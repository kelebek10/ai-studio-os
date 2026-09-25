-- PAI-FORGE M20.3.2 registry seed verification
-- NON-PRODUCTION ONLY. Transactional assertions; no persistent test rows.

BEGIN;

DO $$
DECLARE
  v_count integer;
  v_parent text;
BEGIN
  SELECT count(*) INTO v_count
  FROM m19_control.agent
  WHERE environment = 'NONPROD'
    AND agent_id IN (
      'core:orchestrator',
      'core:security-intelligence',
      'provider:claude',
      'provider:gemini',
      'provider:copilot',
      'specialist:qwen:security-evidence-analyst'
    );

  IF v_count <> 6 THEN
    RAISE EXCEPTION 'M20.3.2 seed agent count mismatch: expected 6, got %', v_count;
  END IF;

  SELECT parent_agent_id INTO v_parent
  FROM m19_control.agent
  WHERE agent_id = 'specialist:qwen:security-evidence-analyst'
    AND environment = 'NONPROD';

  IF v_parent <> 'core:orchestrator' THEN
    RAISE EXCEPTION 'Qwen specialist parent mismatch: %', v_parent;
  END IF;

  IF EXISTS (
    SELECT 1 FROM m19_control.agent
    WHERE agent_type = 'PROVIDER'
      AND environment = 'NONPROD'
      AND enabled = true
  ) THEN
    RAISE EXCEPTION 'Provider runtime was enabled before operational activation gate';
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM m19_control.agent
    WHERE agent_id = 'specialist:qwen:security-evidence-analyst'
      AND enabled = true
      AND status = 'ACTIVE'
      AND authority_level = 'EXECUTION'
  ) THEN
    RAISE EXCEPTION 'Reference specialist is not active/eligible in NONPROD';
  END IF;

  SELECT count(*) INTO v_count
  FROM m19_control.agent_capability
  WHERE environment = 'NONPROD'
    AND agent_id IN ('provider:claude','provider:gemini','provider:copilot')
    AND enabled = false;

  IF v_count <> 3 THEN
    RAISE EXCEPTION 'Provider capability seed count mismatch: expected 3 disabled capabilities, got %', v_count;
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM m19_control.agent_capability
    WHERE agent_id = 'specialist:qwen:security-evidence-analyst'
      AND capability = 'security_evidence_analysis'
      AND environment = 'NONPROD'
      AND enabled = true
      AND max_conflict_rounds = 3
      AND prohibited_actions ? 'governance_approve'
      AND prohibited_actions ? 'production_write'
      AND prohibited_actions ? 'human_gate_bypass'
  ) THEN
    RAISE EXCEPTION 'Qwen security evidence capability boundary mismatch';
  END IF;

  RAISE NOTICE 'M20.3.2 seed verification PASS';
END $$;

ROLLBACK;
