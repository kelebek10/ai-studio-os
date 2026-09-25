-- M20.3.1 registry schema verification
-- Execute only against the NON-PRODUCTION database after 023_m20_3_1_registry_schema.sql.
-- Every negative test is expected to fail with a constraint violation.
\set ON_ERROR_STOP on

BEGIN;

-- Structural assertions.
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='m19_control' AND table_name='agent'
  ) THEN RAISE EXCEPTION 'M20.3.1 FAIL: agent table missing'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables
    WHERE table_schema='m19_control' AND table_name='agent_capability'
  ) THEN RAISE EXCEPTION 'M20.3.1 FAIL: agent_capability table missing'; END IF;
END $$;

-- Positive fixtures.
INSERT INTO m19_control.agent
(agent_id,agent_type,provider,name,role,status,authority_level,environment,model_ref,source_commit,enabled)
VALUES
('test:core:m20_3_1','CORE','internal','M20.3.1 Core','orchestrator','ACTIVE','COORDINATION','NONPROD','test-model','TEST-COMMIT-001',true),
('test:provider:m20_3_1','PROVIDER','test-provider','M20.3.1 Provider','provider','ACTIVE','EXECUTION','NONPROD','test-model','TEST-COMMIT-001',true),
('test:specialist:m20_3_1','SPECIALIST','test-provider','M20.3.1 Specialist','specialist','ACTIVE','NONE','NONPROD','test-model','TEST-COMMIT-001',true,
  'test:provider:m20_3_1');

INSERT INTO m19_control.agent_capability
(agent_id,capability,scope,allowed_actions,prohibited_actions,environment,requires_review,requires_human,max_conflict_rounds,enabled,source_commit)
VALUES
('test:specialist:m20_3_1','security-evidence-analysis','M20.3.1',
 '["read_evidence","classify"]','["approve"]','NONPROD',true,true,3,true,'TEST-COMMIT-001');

-- Positive assertions.
DO $$
BEGIN
  IF (SELECT count(*) FROM m19_control.agent WHERE agent_id LIKE 'test:%:m20_3_1') <> 3
    THEN RAISE EXCEPTION 'M20.3.1 FAIL: agent positive fixtures'; END IF;

  IF (SELECT count(*) FROM m19_control.agent_capability WHERE agent_id='test:specialist:m20_3_1') <> 1
    THEN RAISE EXCEPTION 'M20.3.1 FAIL: capability positive fixture'; END IF;

  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes
    WHERE schemaname='m19_control' AND indexname='agent_capability_identity_uq'
  ) THEN RAISE EXCEPTION 'M20.3.1 FAIL: capability identity index missing'; END IF;
END $$;

-- Negative test 1: duplicate capability identity.
DO $$
BEGIN
  BEGIN
    INSERT INTO m19_control.agent_capability
    (agent_id,capability,scope,environment,source_commit)
    VALUES ('test:specialist:m20_3_1','security-evidence-analysis','M20.3.1','NONPROD','TEST-COMMIT-001');
    RAISE EXCEPTION 'M20.3.1 FAIL: duplicate capability accepted';
  EXCEPTION WHEN unique_violation THEN NULL;
  END;
END $$;

-- Negative test 2: invalid authority.
DO $$
BEGIN
  BEGIN
    INSERT INTO m19_control.agent
    (agent_id,agent_type,provider,name,role,authority_level,environment,model_ref,source_commit)
    VALUES ('test:bad-authority:m20_3_1','SPECIALIST','x','bad','bad','APPROVAL','NONPROD','x','x');
    RAISE EXCEPTION 'M20.3.1 FAIL: invalid authority accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;

-- Negative test 3: specialist without parent.
DO $$
BEGIN
  BEGIN
    INSERT INTO m19_control.agent
    (agent_id,agent_type,provider,name,role,environment,model_ref,source_commit)
    VALUES ('test:bad-parent:m20_3_1','SPECIALIST','x','bad','bad','NONPROD','x','x');
    RAISE EXCEPTION 'M20.3.1 FAIL: specialist without parent accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;

-- Negative test 4: conflict rounds > 3.
DO $$
BEGIN
  BEGIN
    INSERT INTO m19_control.agent_capability
    (agent_id,capability,scope,environment,max_conflict_rounds,source_commit)
    VALUES ('test:specialist:m20_3_1','bad-rounds','M20.3.1','NONPROD',4,'TEST-COMMIT-001');
    RAISE EXCEPTION 'M20.3.1 FAIL: max_conflict_rounds > 3 accepted';
  EXCEPTION WHEN check_violation THEN NULL;
  END;
END $$;

-- Negative test 5: capability referencing missing agent.
DO $$
BEGIN
  BEGIN
    INSERT INTO m19_control.agent_capability
    (agent_id,capability,scope,environment,source_commit)
    VALUES ('test:missing:m20_3_1','x','M20.3.1','NONPROD','TEST-COMMIT-001');
    RAISE EXCEPTION 'M20.3.1 FAIL: missing agent FK accepted';
  EXCEPTION WHEN foreign_key_violation THEN NULL;
  END;
END $$;

ROLLBACK;

SELECT 'M20.3.1 TEST SCRIPT READY — execute against NONPROD; PASS requires zero unexpected exceptions.' AS result;
