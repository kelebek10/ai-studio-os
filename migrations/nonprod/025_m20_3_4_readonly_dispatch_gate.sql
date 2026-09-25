-- M20.3.4 NONPROD read-only dispatch eligibility gate.
-- No registry mutation. No enable/disable side effects.

BEGIN;

CREATE OR REPLACE FUNCTION m19_control.check_dispatch_eligibility(
  p_agent_id text,
  p_capability text,
  p_scope text,
  p_environment text,
  p_requested_action text,
  p_conflict_round integer DEFAULT 0
)
RETURNS TABLE (
  decision text,
  reason_code text
)
LANGUAGE plpgsql
STABLE
AS $$
DECLARE
  a m19_control.agent%ROWTYPE;
  c m19_control.agent_capability%ROWTYPE;
BEGIN
  IF p_environment = 'PRODUCTION' THEN
    RETURN QUERY SELECT 'DISPATCH_BLOCKED', 'PRODUCTION_NOT_AUTHORIZED';
    RETURN;
  END IF;

  SELECT * INTO a
  FROM m19_control.agent
  WHERE agent_id = p_agent_id AND environment = p_environment;

  IF NOT FOUND THEN
    RETURN QUERY SELECT 'DISPATCH_BLOCKED', 'AGENT_NOT_FOUND';
    RETURN;
  END IF;

  IF a.status <> 'ACTIVE' THEN
    RETURN QUERY SELECT 'DISPATCH_BLOCKED', 'AGENT_NOT_ACTIVE';
    RETURN;
  END IF;

  IF NOT a.enabled THEN
    RETURN QUERY SELECT 'DISPATCH_BLOCKED', 'AGENT_DISABLED';
    RETURN;
  END IF;

  IF a.agent_type = 'SPECIALIST' THEN
    IF a.parent_agent_id IS NULL THEN
      RETURN QUERY SELECT 'DISPATCH_BLOCKED', 'SPECIALIST_PARENT_MISSING';
      RETURN;
    END IF;
    IF NOT EXISTS (
      SELECT 1 FROM m19_control.agent p
      WHERE p.agent_id = a.parent_agent_id
        AND p.environment = p_environment
        AND p.status = 'ACTIVE'
        AND p.enabled = true
    ) THEN
      RETURN QUERY SELECT 'DISPATCH_BLOCKED', 'PARENT_NOT_OPERATIONAL';
      RETURN;
    END IF;
  END IF;

  SELECT * INTO c
  FROM m19_control.agent_capability
  WHERE agent_id = p_agent_id
    AND capability = p_capability
    AND scope = p_scope
    AND environment = p_environment;

  IF NOT FOUND THEN
    RETURN QUERY SELECT 'DISPATCH_BLOCKED', 'CAPABILITY_NOT_FOUND';
    RETURN;
  END IF;

  IF NOT c.enabled THEN
    RETURN QUERY SELECT 'DISPATCH_BLOCKED', 'CAPABILITY_DISABLED';
    RETURN;
  END IF;

  IF NOT (c.allowed_actions @> jsonb_build_array(p_requested_action)) THEN
    RETURN QUERY SELECT 'DISPATCH_BLOCKED', 'ACTION_NOT_ALLOWED';
    RETURN;
  END IF;

  IF c.prohibited_actions @> jsonb_build_array(p_requested_action) THEN
    RETURN QUERY SELECT 'DISPATCH_BLOCKED', 'ACTION_PROHIBITED';
    RETURN;
  END IF;

  IF p_conflict_round < 0 OR p_conflict_round > c.max_conflict_rounds THEN
    RETURN QUERY SELECT 'DISPATCH_BLOCKED', 'CONFLICT_ROUND_EXCEEDED';
    RETURN;
  END IF;

  IF c.requires_human THEN
    RETURN QUERY SELECT 'DISPATCH_BLOCKED', 'HUMAN_GATE_REQUIRED';
    RETURN;
  END IF;

  RETURN QUERY SELECT 'ELIGIBLE', 'ELIGIBILITY_PASS';
END;
$$;

COMMENT ON FUNCTION m19_control.check_dispatch_eligibility IS
'Read-only deterministic registry eligibility gate. Never mutates registry state and never grants approval authority.';

COMMIT;
