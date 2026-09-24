-- M18 production-safe candidate migration.
-- NON-DESTRUCTIVE / IDEMPOTENT: never drop schema, tables, roles, or data.
CREATE SCHEMA IF NOT EXISTS m18_agent_registry;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='paiforge_m18_orchestrator') THEN CREATE ROLE paiforge_m18_orchestrator NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='paiforge_m18_human_approver') THEN CREATE ROLE paiforge_m18_human_approver NOLOGIN; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='paiforge_m18_ai_provider') THEN CREATE ROLE paiforge_m18_ai_provider NOLOGIN; END IF;
END $$;

CREATE TABLE IF NOT EXISTS m18_agent_registry.agent (
  agent_id text PRIMARY KEY,
  name text NOT NULL,
  tier text NOT NULL CHECK (tier IN ('CORE','SPECIALIST')),
  scope text NOT NULL,
  provider text,
  parent_agent_id text,
  status text NOT NULL DEFAULT 'ACTIVE' CHECK (status IN ('ACTIVE','DISABLED')),
  approval_id text,
  created_by_principal text NOT NULL DEFAULT current_user,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS m18_agent_registry.audit_event (
  event_id bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  agent_id text NOT NULL REFERENCES m18_agent_registry.agent(agent_id),
  event_type text NOT NULL,
  actor_principal text NOT NULL,
  approval_id text,
  created_at timestamptz NOT NULL DEFAULT now()
);

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname='m18_agent_tier_shape_ck') THEN
    ALTER TABLE m18_agent_registry.agent ADD CONSTRAINT m18_agent_tier_shape_ck CHECK (
      (tier='CORE' AND provider IS NULL AND parent_agent_id IS NULL AND approval_id IS NOT NULL AND approval_id <> '')
      OR
      (tier='SPECIALIST' AND provider IN ('GEMINI','CLAUDE','COPILOT','QWEN') AND parent_agent_id IS NOT NULL AND approval_id IS NULL)
    );
  END IF;
END $$;

CREATE OR REPLACE FUNCTION m18_agent_registry.enforce_limits()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE v_core integer; v_specialists integer; v_provider integer; v_parent_tier text;
BEGIN
  IF NEW.tier='CORE' THEN
    SELECT count(*) INTO v_core FROM m18_agent_registry.agent WHERE tier='CORE' AND status='ACTIVE';
    IF v_core >= 12 THEN RAISE EXCEPTION 'CORE_AGENT_LIMIT_REACHED'; END IF;
  ELSE
    SELECT tier INTO v_parent_tier FROM m18_agent_registry.agent WHERE agent_id=NEW.parent_agent_id AND status='ACTIVE';
    IF v_parent_tier <> 'CORE' THEN RAISE EXCEPTION 'SPECIALIST_PARENT_MUST_BE_CORE'; END IF;
    SELECT count(*) INTO v_specialists FROM m18_agent_registry.agent WHERE tier='SPECIALIST' AND status='ACTIVE';
    IF v_specialists >= 36 THEN RAISE EXCEPTION 'SPECIALIST_AGENT_LIMIT_REACHED'; END IF;
    SELECT count(*) INTO v_provider FROM m18_agent_registry.agent WHERE tier='SPECIALIST' AND status='ACTIVE' AND provider=NEW.provider;
    IF v_provider >= 9 THEN RAISE EXCEPTION 'PROVIDER_SPECIALIST_LIMIT_REACHED'; END IF;
  END IF;
  RETURN NEW;
END;
$$;

CREATE OR REPLACE FUNCTION m18_agent_registry.audit_agent_insert()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  INSERT INTO m18_agent_registry.audit_event(agent_id,event_type,actor_principal,approval_id)
  VALUES (NEW.agent_id, CASE WHEN NEW.tier='CORE' THEN 'CORE_CREATED' ELSE 'SPECIALIST_CREATED' END, current_user, NEW.approval_id);
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS agent_enforce_limits ON m18_agent_registry.agent;
CREATE TRIGGER agent_enforce_limits BEFORE INSERT ON m18_agent_registry.agent FOR EACH ROW EXECUTE FUNCTION m18_agent_registry.enforce_limits();
DROP TRIGGER IF EXISTS agent_audit_insert ON m18_agent_registry.agent;
CREATE TRIGGER agent_audit_insert AFTER INSERT ON m18_agent_registry.agent FOR EACH ROW EXECUTE FUNCTION m18_agent_registry.audit_agent_insert();

ALTER TABLE m18_agent_registry.agent ENABLE ROW LEVEL SECURITY;
ALTER TABLE m18_agent_registry.audit_event ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS agent_read_orchestrator ON m18_agent_registry.agent;
CREATE POLICY agent_read_orchestrator ON m18_agent_registry.agent FOR SELECT TO paiforge_m18_orchestrator USING (true);
DROP POLICY IF EXISTS agent_read_provider ON m18_agent_registry.agent;
CREATE POLICY agent_read_provider ON m18_agent_registry.agent FOR SELECT TO paiforge_m18_ai_provider USING (true);
DROP POLICY IF EXISTS agent_read_human ON m18_agent_registry.agent;
CREATE POLICY agent_read_human ON m18_agent_registry.agent FOR SELECT TO paiforge_m18_human_approver USING (true);
DROP POLICY IF EXISTS agent_insert_orchestrator ON m18_agent_registry.agent;
CREATE POLICY agent_insert_orchestrator ON m18_agent_registry.agent FOR INSERT TO paiforge_m18_orchestrator WITH CHECK (tier='SPECIALIST' AND provider IN ('GEMINI','CLAUDE','COPILOT','QWEN') AND approval_id IS NULL);
DROP POLICY IF EXISTS agent_insert_human ON m18_agent_registry.agent;
CREATE POLICY agent_insert_human ON m18_agent_registry.agent FOR INSERT TO paiforge_m18_human_approver WITH CHECK (tier='CORE' AND provider IS NULL AND parent_agent_id IS NULL AND approval_id IS NOT NULL AND approval_id <> '');
DROP POLICY IF EXISTS audit_read_orchestrator ON m18_agent_registry.audit_event;
CREATE POLICY audit_read_orchestrator ON m18_agent_registry.audit_event FOR SELECT TO paiforge_m18_orchestrator USING (true);
DROP POLICY IF EXISTS audit_read_human ON m18_agent_registry.audit_event;
CREATE POLICY audit_read_human ON m18_agent_registry.audit_event FOR SELECT TO paiforge_m18_human_approver USING (true);

REVOKE ALL ON SCHEMA m18_agent_registry FROM PUBLIC;
GRANT USAGE ON SCHEMA m18_agent_registry TO paiforge_m18_orchestrator,paiforge_m18_human_approver,paiforge_m18_ai_provider;
GRANT SELECT,INSERT ON m18_agent_registry.agent TO paiforge_m18_orchestrator,paiforge_m18_human_approver;
GRANT SELECT ON m18_agent_registry.agent TO paiforge_m18_ai_provider;
GRANT SELECT ON m18_agent_registry.audit_event TO paiforge_m18_orchestrator,paiforge_m18_human_approver;
