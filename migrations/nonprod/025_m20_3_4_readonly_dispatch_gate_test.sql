-- M20.3.4 NONPROD deterministic gate tests.
BEGIN;

DO $$
DECLARE r record;
BEGIN
  -- Disabled provider must be blocked.
  SELECT * INTO r FROM m19_control.check_dispatch_eligibility(
    'provider:claude','architecture_review','provider_review','NONPROD','review_architecture',0
  );
  IF r.decision <> 'DISPATCH_BLOCKED' OR r.reason_code <> 'AGENT_DISABLED' THEN
    RAISE EXCEPTION 'T01 failed: expected AGENT_DISABLED, got %/%', r.decision, r.reason_code;
  END IF;

  -- Disabled capability must be blocked (fixture uses Qwen specialist if enabled in seed).
  SELECT * INTO r FROM m19_control.check_dispatch_eligibility(
    'provider:gemini','data_model_scalability_review','provider_review','NONPROD','review_schema',0
  );
  IF r.decision <> 'DISPATCH_BLOCKED' OR r.reason_code <> 'AGENT_DISABLED' THEN
    RAISE EXCEPTION 'T02 failed: expected AGENT_DISABLED, got %/%', r.decision, r.reason_code;
  END IF;

  -- Production target is always blocked.
  SELECT * INTO r FROM m19_control.check_dispatch_eligibility(
    'core:orchestrator','architecture_review','provider_review','PRODUCTION','review_architecture',0
  );
  IF r.decision <> 'DISPATCH_BLOCKED' OR r.reason_code <> 'PRODUCTION_NOT_AUTHORIZED' THEN
    RAISE EXCEPTION 'T03 failed: expected PRODUCTION_NOT_AUTHORIZED, got %/%', r.decision, r.reason_code;
  END IF;

  -- Missing agent is blocked.
  SELECT * INTO r FROM m19_control.check_dispatch_eligibility(
    'missing:agent','x','x','NONPROD','x',0
  );
  IF r.decision <> 'DISPATCH_BLOCKED' OR r.reason_code <> 'AGENT_NOT_FOUND' THEN
    RAISE EXCEPTION 'T04 failed: expected AGENT_NOT_FOUND, got %/%', r.decision, r.reason_code;
  END IF;
END $$;

-- Verify gate is read-only: registry counts and enabled states remain unchanged.
DO $$
DECLARE
  disabled_count integer;
BEGIN
  SELECT count(*) INTO disabled_count
  FROM m19_control.agent
  WHERE agent_id IN ('provider:claude','provider:gemini','provider:copilot')
    AND enabled = false;
  IF disabled_count <> 3 THEN
    RAISE EXCEPTION 'T05 failed: provider disabled invariant changed';
  END IF;
END $$;

ROLLBACK;
