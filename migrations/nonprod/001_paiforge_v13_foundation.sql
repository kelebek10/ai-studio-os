-- PAI-FORGE PostgreSQL v1.3 foundation migration
-- STATUS: NON-PRODUCTION TEST ARTIFACT
-- Branch: phase-1-3-foundation
-- Target: disposable PostgreSQL 16 only
-- This artifact is intentionally not a production cutover script.

BEGIN;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE SCHEMA IF NOT EXISTS core;
CREATE SCHEMA IF NOT EXISTS evidence;
CREATE SCHEMA IF NOT EXISTS research;
CREATE SCHEMA IF NOT EXISTS tenant;
CREATE SCHEMA IF NOT EXISTS governance;

CREATE TABLE IF NOT EXISTS tenant.tenant (
  tenant_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  name text NOT NULL,
  status text NOT NULL CHECK (status IN ('ACTIVE','SUSPENDED','ARCHIVED')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS core.entity (
  entity_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type text NOT NULL CHECK (entity_type IN ('PLANT','SITE','MATERIAL','DESIGN','OTHER')),
  scientific_identity_key text NOT NULL UNIQUE,
  canonical_name text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0),
  status text NOT NULL CHECK (status IN ('ACTIVE','INACTIVE','SUPERSEDED'))
);

CREATE TABLE IF NOT EXISTS core.entity_relationship (
  relationship_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  from_entity_id uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT,
  to_entity_id uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT,
  relationship_type text NOT NULL CHECK (relationship_type IN ('RELATED','COMPATIBLE','CONFLICTS','DERIVED_FROM')),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  UNIQUE(from_entity_id,to_entity_id,relationship_type)
);

CREATE TABLE IF NOT EXISTS core.knowledge (
  knowledge_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT,
  knowledge_type text NOT NULL CHECK (knowledge_type IN ('SCIENTIFIC','HORTICULTURAL','ENVIRONMENTAL','OPERATIONAL')),
  state text NOT NULL CHECK (state IN ('CANDIDATE','VERIFIED','APPROVED','INVALIDATED')),
  payload jsonb NOT NULL,
  ruleset_version text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  version bigint NOT NULL DEFAULT 1 CHECK (version > 0)
);

CREATE TABLE IF NOT EXISTS core.event_history (
  event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_id uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT,
  event_sequence bigint NOT NULL CHECK (event_sequence > 0),
  event_type text NOT NULL CHECK (event_type IN ('CREATED','UPDATED','APPROVED','INVALIDATED','SUPERSEDED')),
  aggregate_version bigint NOT NULL CHECK (aggregate_version > 0),
  actor_id uuid NOT NULL,
  actor_role text NOT NULL,
  model_id text,
  model_version text,
  ruleset_version text,
  payload jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(entity_id,event_sequence)
);

CREATE TABLE IF NOT EXISTS evidence.record (
  evidence_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_system text NOT NULL,
  source_record_key text NOT NULL,
  source_version text NOT NULL,
  content_hash text NOT NULL,
  captured_at timestamptz NOT NULL,
  verification_state text NOT NULL CHECK (verification_state IN ('UNVERIFIED','VERIFIED','REJECTED')),
  status text NOT NULL CHECK (status IN ('ACTIVE','INVALIDATED','SUPERSEDED')),
  actor_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS evidence.knowledge_link (
  evidence_id uuid NOT NULL REFERENCES evidence.record(evidence_id) ON DELETE RESTRICT,
  knowledge_id uuid NOT NULL REFERENCES core.knowledge(knowledge_id) ON DELETE RESTRICT,
  link_type text NOT NULL CHECK (link_type IN ('SUPPORTS','DERIVED_FROM','CONTRADICTS')),
  created_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(evidence_id,knowledge_id)
);

CREATE TABLE IF NOT EXISTS research.raw_record (
  raw_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  source_system text NOT NULL,
  source_record_key text NOT NULL,
  payload jsonb NOT NULL,
  payload_hash text NOT NULL,
  captured_at timestamptz NOT NULL,
  actor_id uuid NOT NULL,
  idempotency_key text NOT NULL UNIQUE
);

CREATE TABLE IF NOT EXISTS research.proposal (
  proposal_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  proposal_fingerprint text NOT NULL UNIQUE,
  proposed_entity_id uuid REFERENCES core.entity(entity_id) ON DELETE RESTRICT,
  proposed_knowledge_id uuid REFERENCES core.knowledge(knowledge_id) ON DELETE RESTRICT,
  model_id text NOT NULL,
  model_version text NOT NULL,
  ruleset_version text NOT NULL,
  actor_id uuid NOT NULL,
  status text NOT NULL CHECK (status IN ('CANDIDATE','VERIFIED','REJECTED','SUPERSEDED')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS tenant.entity_override (
  tenant_id uuid NOT NULL REFERENCES tenant.tenant(tenant_id) ON DELETE RESTRICT,
  entity_id uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT,
  payload jsonb NOT NULL,
  version bigint NOT NULL CHECK (version > 0),
  status text NOT NULL CHECK (status IN ('ACTIVE','INACTIVE','SUPERSEDED')),
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now(),
  PRIMARY KEY(tenant_id,entity_id)
);

CREATE TABLE IF NOT EXISTS core.approval (
  approval_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  proposal_id uuid REFERENCES research.proposal(proposal_id) ON DELETE RESTRICT,
  knowledge_id uuid NOT NULL REFERENCES core.knowledge(knowledge_id) ON DELETE RESTRICT,
  actor_id uuid NOT NULL,
  actor_role text NOT NULL,
  workflow_type text NOT NULL,
  expected_version bigint NOT NULL CHECK (expected_version > 0),
  event_sequence bigint NOT NULL CHECK (event_sequence > 0),
  idempotency_key text NOT NULL UNIQUE,
  approval_type text NOT NULL CHECK (approval_type IN ('HUMAN_APPROVED','HUMAN_REJECTED','ENGINEERING_REVIEW')),
  approved_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS core.constraint (
  constraint_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  constraint_key text NOT NULL UNIQUE,
  classification text NOT NULL CHECK (classification IN ('SAFETY_ENGINEERING','CUSTOMER_HARD','CUSTOMER_GOAL','PREFERENCE','OPTIMIZATION','AESTHETIC')),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL
);

CREATE TABLE IF NOT EXISTS core.constraint_version (
  constraint_version_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  constraint_id uuid NOT NULL REFERENCES core.constraint(constraint_id) ON DELETE RESTRICT,
  version bigint NOT NULL CHECK (version > 0),
  enforcement text NOT NULL CHECK (enforcement IN ('NON_NEGOTIABLE','HARD','SOFT','INFORMATIONAL')),
  priority text NOT NULL CHECK (priority IN ('P0','P1','P2','P3','P4')),
  ruleset_version text NOT NULL,
  content_hash text NOT NULL,
  provenance_ref uuid REFERENCES evidence.record(evidence_id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  UNIQUE(constraint_id,version)
  -- Safety classification CHECK is added after the helper function is created below.
  -- PostgreSQL cannot resolve a function that does not yet exist during CREATE TABLE.
);

CREATE TABLE IF NOT EXISTS governance.design_state (
  design_state_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  design_id uuid NOT NULL,
  state_version bigint NOT NULL CHECK (state_version > 0),
  state_hash text NOT NULL,
  ruleset_version text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL,
  UNIQUE(design_id,state_version),
  UNIQUE(design_id,state_hash)
);

CREATE TABLE IF NOT EXISTS governance.impact_dependency (
  impact_dependency_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  design_state_id uuid NOT NULL REFERENCES governance.design_state(design_state_id) ON DELETE RESTRICT,
  source_type text NOT NULL CHECK (source_type IN ('ACTION','CONSTRAINT','ENTITY','SITE','DESIGN')),
  source_id uuid NOT NULL,
  impact_type text NOT NULL CHECK (impact_type IN ('POSITIVE','NEGATIVE','NEUTRAL','BLOCKING')),
  dependency_type text NOT NULL CHECK (dependency_type IN ('REQUIRES','CONFLICTS_WITH','AFFECTS','DEPENDS_ON')),
  result text NOT NULL CHECK (result IN ('CONFIRMED','UNKNOWN','REQUIRES_REVIEW')),
  ruleset_version text NOT NULL,
  provenance_ref uuid REFERENCES evidence.record(evidence_id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS governance.feasibility_evaluation (
  feasibility_evaluation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  design_state_id uuid NOT NULL REFERENCES governance.design_state(design_state_id) ON DELETE RESTRICT,
  input_hash text NOT NULL,
  result text NOT NULL CHECK (result IN ('FEASIBLE','INFEASIBLE','PARTIALLY_FEASIBLE','REQUIRES_REVIEW')),
  engine_id text NOT NULL,
  engine_version text NOT NULL,
  ruleset_version text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS governance.conflict (
  conflict_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  action_id uuid NOT NULL,
  change_request_id uuid,
  design_state_id uuid NOT NULL REFERENCES governance.design_state(design_state_id) ON DELETE RESTRICT,
  state_version bigint NOT NULL CHECK (state_version > 0),
  state_hash text NOT NULL,
  status text NOT NULL CHECK (status IN ('OPEN','RESOLVED','REQUIRES_ENGINEERING_REVIEW','SUPERSEDED')),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL
);

CREATE TABLE IF NOT EXISTS governance.conflict_constraint (
  conflict_id uuid NOT NULL REFERENCES governance.conflict(conflict_id) ON DELETE RESTRICT,
  constraint_version_id uuid NOT NULL REFERENCES core.constraint_version(constraint_version_id) ON DELETE RESTRICT,
  PRIMARY KEY(conflict_id,constraint_version_id)
);

CREATE TABLE IF NOT EXISTS governance.alternative (
  alternative_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conflict_id uuid NOT NULL REFERENCES governance.conflict(conflict_id) ON DELETE RESTRICT,
  status text NOT NULL CHECK (status IN ('CANDIDATE','FEASIBLE','INFEASIBLE','SELECTED','REJECTED')),
  proposal_hash text NOT NULL,
  feasibility_id uuid REFERENCES governance.feasibility_evaluation(feasibility_evaluation_id) ON DELETE RESTRICT,
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL
);

CREATE TABLE IF NOT EXISTS governance.resolution (
  resolution_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  conflict_id uuid NOT NULL REFERENCES governance.conflict(conflict_id) ON DELETE RESTRICT,
  alternative_id uuid REFERENCES governance.alternative(alternative_id) ON DELETE RESTRICT,
  status text NOT NULL CHECK (status IN ('PROPOSED','APPROVED','REJECTED','ENGINEERING_REVIEW')),
  decision_hash text NOT NULL,
  actor_id uuid NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS governance.approval_event (
  approval_event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  resolution_id uuid NOT NULL REFERENCES governance.resolution(resolution_id) ON DELETE RESTRICT,
  event_type text NOT NULL CHECK (event_type IN ('SUBMITTED','APPROVED','REJECTED','ENGINEERING_REVIEW')),
  actor_id uuid NOT NULL,
  actor_role text NOT NULL,
  authorization_ref text NOT NULL,
  idempotency_key text NOT NULL UNIQUE,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS governance.change_request (
  change_request_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  request_key text NOT NULL UNIQUE,
  design_state_id uuid NOT NULL REFERENCES governance.design_state(design_state_id) ON DELETE RESTRICT,
  expected_state_version bigint NOT NULL CHECK (expected_state_version > 0),
  canonical_request_hash text NOT NULL,
  status text NOT NULL CHECK (status IN ('CANDIDATE','VERIFIED','APPROVED','REJECTED','STALE','APPLIED')),
  created_at timestamptz NOT NULL DEFAULT now(),
  created_by uuid NOT NULL
);

CREATE INDEX IF NOT EXISTS ix_constraint_version_lookup ON core.constraint_version(constraint_id,version);
CREATE INDEX IF NOT EXISTS ix_design_state_version ON governance.design_state(design_id,state_version);
CREATE INDEX IF NOT EXISTS ix_design_state_hash ON governance.design_state(design_id,state_hash);
CREATE INDEX IF NOT EXISTS ix_conflict_state ON governance.conflict(design_state_id,state_version,state_hash);
CREATE INDEX IF NOT EXISTS ix_feasibility_input ON governance.feasibility_evaluation(input_hash);
CREATE INDEX IF NOT EXISTS ix_change_request_hash ON governance.change_request(canonical_request_hash);

-- Safety classification helper. Kept immutable and deterministic.
CREATE OR REPLACE FUNCTION core.classification_is_safety(cid uuid)
RETURNS boolean LANGUAGE sql IMMUTABLE AS $$
  SELECT classification = 'SAFETY_ENGINEERING' FROM core.constraint WHERE constraint_id = cid;
$$;

-- Replace the forward-reference CHECK after helper creation.
ALTER TABLE core.constraint_version DROP CONSTRAINT IF EXISTS constraint_version_classification_is_safety_check;
ALTER TABLE core.constraint_version ADD CONSTRAINT constraint_version_classification_is_safety_check
  CHECK (NOT (core.classification_is_safety(constraint_id) AND enforcement <> 'NON_NEGOTIABLE'));

-- Preserve the existing verification contract's deterministic error semantics:
-- policy violations are surfaced as a named exception before the defensive CHECK.
CREATE OR REPLACE FUNCTION core.validate_constraint_version_policy()
RETURNS trigger
LANGUAGE plpgsql
AS $
BEGIN
  IF core.classification_is_safety(NEW.constraint_id)
     AND NEW.enforcement <> 'NON_NEGOTIABLE' THEN
    RAISE EXCEPTION 'SAFETY_ENGINEERING_REQUIRES_NON_NEGOTIABLE';
  END IF;
  RETURN NEW;
END;
$;

CREATE TRIGGER trg_constraint_version_policy
BEFORE INSERT OR UPDATE OF constraint_id, enforcement ON core.constraint_version
FOR EACH ROW EXECUTE FUNCTION core.validate_constraint_version_policy();

-- Database-enforced immutability for historical/governance records.
CREATE OR REPLACE FUNCTION governance.reject_mutation()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'IMMUTABLE_RECORD: % is append-only', TG_TABLE_NAME;
END;
$$;

CREATE TRIGGER trg_design_state_immutable BEFORE UPDATE OR DELETE ON governance.design_state
FOR EACH ROW EXECUTE FUNCTION governance.reject_mutation();
CREATE TRIGGER trg_resolution_immutable BEFORE UPDATE OR DELETE ON governance.resolution
FOR EACH ROW EXECUTE FUNCTION governance.reject_mutation();
CREATE TRIGGER trg_approval_event_immutable BEFORE UPDATE OR DELETE ON governance.approval_event
FOR EACH ROW EXECUTE FUNCTION governance.reject_mutation();
CREATE TRIGGER trg_conflict_immutable BEFORE UPDATE OR DELETE ON governance.conflict
FOR EACH ROW EXECUTE FUNCTION governance.reject_mutation();

-- Conflict state/hash must match the exact Design State snapshot.
CREATE OR REPLACE FUNCTION governance.validate_conflict_snapshot()
RETURNS trigger LANGUAGE plpgsql AS $$
DECLARE sv bigint; sh text;
BEGIN
  SELECT state_version,state_hash INTO sv,sh FROM governance.design_state WHERE design_state_id=NEW.design_state_id;
  IF sv IS NULL OR sv <> NEW.state_version OR sh <> NEW.state_hash THEN
    RAISE EXCEPTION 'CONFLICT_STATE_MISMATCH';
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER trg_conflict_snapshot BEFORE INSERT ON governance.conflict
FOR EACH ROW EXECUTE FUNCTION governance.validate_conflict_snapshot();

-- PARTIALLY_FEASIBLE can never be represented as an automatic approval.
CREATE OR REPLACE FUNCTION governance.reject_partial_auto_apply()
RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.result='PARTIALLY_FEASIBLE' THEN
    RAISE EXCEPTION 'PARTIALLY_FEASIBLE_REQUIRES_REVIEW';
  END IF;
  RETURN NEW;
END;
$$;
CREATE TRIGGER trg_partial_feasibility BEFORE INSERT ON governance.feasibility_evaluation
FOR EACH ROW EXECUTE FUNCTION governance.reject_partial_auto_apply();

-- Tenant isolation boundary.
ALTER TABLE tenant.entity_override ENABLE ROW LEVEL SECURITY;
ALTER TABLE tenant.entity_override FORCE ROW LEVEL SECURITY;

CREATE OR REPLACE FUNCTION tenant.current_tenant_id()
RETURNS uuid LANGUAGE sql STABLE AS $$
  SELECT NULLIF(current_setting('app.tenant_id', true),'')::uuid;
$$;

CREATE POLICY tenant_entity_override_isolation ON tenant.entity_override
USING (tenant_id = tenant.current_tenant_id())
WITH CHECK (tenant_id = tenant.current_tenant_id());

CREATE TABLE IF NOT EXISTS governance.migration_ledger (
  migration_id text PRIMARY KEY,
  applied_at timestamptz NOT NULL DEFAULT now(),
  artifact_hash text NOT NULL,
  environment text NOT NULL CHECK (environment='NONPROD')
);

INSERT INTO governance.migration_ledger(migration_id,artifact_hash,environment)
VALUES ('001_paiforge_v13_foundation','NONPROD-ARTIFACT-HASH-TO-BE-RECORDED','NONPROD')
ON CONFLICT (migration_id) DO NOTHING;

COMMIT;
