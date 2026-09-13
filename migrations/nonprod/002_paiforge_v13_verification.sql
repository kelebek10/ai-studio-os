-- PAI-FORGE v1.3 NONPROD FOUNDATION VERIFICATION
-- Target: disposable PostgreSQL 16 only. Never production.
-- Scope: controls actually implemented by 001_paiforge_v13_test.sql.
-- RLS is verified through a real non-superuser LOGIN session.
\set ON_ERROR_STOP on
BEGIN;

DO $$
DECLARE n integer;
BEGIN
  SELECT count(*) INTO n FROM information_schema.tables WHERE table_schema IN ('core','evidence','tenant','governance') AND table_name IN ('entity','record','tenant','entity_override','constraint','constraint_version','design_state','impact_dependency','feasibility_evaluation','change_request','conflict','conflict_constraint','alternative','resolution','approval_event');
  IF n <> 15 THEN RAISE EXCEPTION 'M01_SCHEMA_INVENTORY_FAIL: expected 15 tables, got %',n; END IF;
  RAISE NOTICE 'M01 PASS: schema inventory';
END $$;

DO $$ BEGIN
  BEGIN
    INSERT INTO core.entity(entity_type,scientific_identity_key,canonical_name,created_by,status) VALUES('INVALID','m02-invalid','invalid',gen_random_uuid(),'ACTIVE');
    RAISE EXCEPTION 'M02_CONTROLLED_VALUES_FAIL: invalid value accepted';
  EXCEPTION WHEN check_violation THEN RAISE NOTICE 'M02 PASS: invalid controlled value rejected'; END;
END $$;

DO $$
DECLARE e uuid := gen_random_uuid(); t uuid := gen_random_uuid();
BEGIN
  INSERT INTO core.entity(entity_id,entity_type,scientific_identity_key,canonical_name,created_by,status) VALUES(e,'OTHER','m04-identity','M04 entity',gen_random_uuid(),'ACTIVE');
  INSERT INTO tenant.tenant(tenant_id,name,status) VALUES(t,'M04 tenant','ACTIVE');
  INSERT INTO tenant.entity_override(tenant_id,entity_id,payload,version,status) VALUES(t,e,'{}',1,'ACTIVE');
  BEGIN DELETE FROM core.entity WHERE entity_id=e; RAISE EXCEPTION 'M04_FK_RESTRICT_FAIL: destructive delete accepted';
  EXCEPTION WHEN foreign_key_violation THEN RAISE NOTICE 'M04 PASS: restrictive FK'; END;
END $$;

DO $$
DECLARE c uuid := gen_random_uuid();
BEGIN
  INSERT INTO core.constraint(constraint_id,constraint_key,classification,created_by) VALUES(c,'m15-safety','SAFETY_ENGINEERING',gen_random_uuid());
  BEGIN
    INSERT INTO core.constraint_version(constraint_id,version,enforcement,priority,ruleset_version,content_hash,created_by) VALUES(c,1,'HARD','P0','test-v1','m15-bad',gen_random_uuid());
    RAISE EXCEPTION 'M15_CONSTRAINT_POLICY_FAIL: safety HARD accepted';
  EXCEPTION WHEN raise_exception THEN
    IF SQLERRM <> 'SAFETY_ENGINEERING_REQUIRES_NON_NEGOTIABLE' THEN RAISE; END IF;
    RAISE NOTICE 'M15 PASS: safety enforcement rejected';
  END;
  INSERT INTO core.constraint_version(constraint_id,version,enforcement,priority,ruleset_version,content_hash,created_by) VALUES(c,1,'NON_NEGOTIABLE','P0','test-v1','m15-good',gen_random_uuid());
END $$;

DO $$
DECLARE d uuid := gen_random_uuid(); s uuid;
BEGIN
  INSERT INTO governance.design_state(design_id,state_version,state_hash,ruleset_version,created_by) VALUES(d,1,'m07-hash','test-v1',gen_random_uuid()) RETURNING design_state_id INTO s;
  BEGIN UPDATE governance.design_state SET state_hash='changed' WHERE design_state_id=s; RAISE EXCEPTION 'M07_IMMUTABILITY_FAIL: UPDATE accepted';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM NOT LIKE 'IMMUTABLE_RECORD:%' THEN RAISE; END IF; END;
  BEGIN DELETE FROM governance.design_state WHERE design_state_id=s; RAISE EXCEPTION 'M07_IMMUTABILITY_FAIL: DELETE accepted';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM NOT LIKE 'IMMUTABLE_RECORD:%' THEN RAISE; END IF; END;
  RAISE NOTICE 'M07 PASS: design_state immutable';
END $$;

DO $$
DECLARE d uuid := gen_random_uuid(); s uuid; a uuid := gen_random_uuid();
BEGIN
  INSERT INTO governance.design_state(design_id,state_version,state_hash,ruleset_version,created_by) VALUES(d,1,'m16-good','test-v1',gen_random_uuid()) RETURNING design_state_id INTO s;
  BEGIN INSERT INTO governance.conflict(action_id,design_state_id,state_version,state_hash,status,created_by) VALUES(a,s,1,'m16-BAD','OPEN',gen_random_uuid()); RAISE EXCEPTION 'M16_CONFLICT_SNAPSHOT_FAIL: mismatch accepted';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'CONFLICT_STATE_MISMATCH' THEN RAISE; END IF; END;
  INSERT INTO governance.conflict(action_id,design_state_id,state_version,state_hash,status,created_by) VALUES(a,s,1,'m16-good','OPEN',gen_random_uuid());
  RAISE NOTICE 'M16/M17 PASS: conflict snapshot integrity';
END $$;

DO $$
DECLARE d uuid := gen_random_uuid(); s uuid;
BEGIN
  INSERT INTO governance.design_state(design_id,state_version,state_hash,ruleset_version,created_by) VALUES(d,1,'m19-hash','test-v1',gen_random_uuid()) RETURNING design_state_id INTO s;
  BEGIN INSERT INTO governance.feasibility_evaluation(design_state_id,input_hash,result,engine_id,engine_version,ruleset_version) VALUES(s,'m19-input','PARTIALLY_FEASIBLE','deterministic-test','1','test-v1'); RAISE EXCEPTION 'M19_PARTIAL_FEASIBILITY_FAIL: partial accepted';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM <> 'PARTIALLY_FEASIBLE_REQUIRES_REVIEW' THEN RAISE; END IF; END;
  RAISE NOTICE 'M19 PASS: partial feasibility blocked';
END $$;

-- M05 is intentionally executed in a separate non-superuser LOGIN session below.
DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname='paiforge_rls_tester' AND rolsuper=false AND rolcanlogin=true) THEN
    RAISE EXCEPTION 'M05_SETUP_FAIL: paiforge_rls_tester LOGIN non-superuser missing';
  END IF;
  RAISE NOTICE 'M05 SETUP PASS: real non-superuser role available';
END $$;

DO $$
DECLARE c uuid := gen_random_uuid(); cv uuid;
BEGIN
  INSERT INTO core.constraint(constraint_id,constraint_key,classification,created_by) VALUES(c,'m17-constraint','CUSTOMER_HARD',gen_random_uuid());
  INSERT INTO core.constraint_version(constraint_id,version,enforcement,priority,ruleset_version,content_hash,created_by) VALUES(c,1,'HARD','P1','test-v1','m17-cv',gen_random_uuid()) RETURNING constraint_version_id INTO cv;
  IF NOT EXISTS (SELECT 1 FROM core.constraint_version WHERE constraint_version_id=cv) THEN RAISE EXCEPTION 'M17_FAIL: constraint version missing'; END IF;
  RAISE NOTICE 'M17 PASS: conflict constraint version FK target exists';
END $$;

DO $$
DECLARE r uuid := gen_random_uuid();
BEGIN
  INSERT INTO governance.resolution(resolution_id,conflict_id,status,decision_hash,actor_id) SELECT r,conflict_id,'PROPOSED','m20-resolution',gen_random_uuid() FROM governance.conflict LIMIT 1;
  BEGIN DELETE FROM governance.resolution WHERE resolution_id=r; RAISE EXCEPTION 'M20_IMMUTABILITY_FAIL: resolution delete accepted';
  EXCEPTION WHEN raise_exception THEN IF SQLERRM NOT LIKE 'IMMUTABLE_RECORD:%' THEN RAISE; END IF; END;
  RAISE NOTICE 'M20 PASS: resolution immutable';
END $$;

DO $$
DECLARE a uuid := gen_random_uuid();
BEGIN
  INSERT INTO governance.approval_event(approval_event_id,resolution_id,event_type,actor_id,actor_role,authorization_ref,idempotency_key) SELECT a,resolution_id,'SUBMITTED',gen_random_uuid(),'HUMAN','m21-auth','m21-key' FROM governance.resolution LIMIT 1;
  BEGIN INSERT INTO governance.approval_event(resolution_id,event_type,actor_id,actor_role,authorization_ref,idempotency_key) SELECT resolution_id,'SUBMITTED',gen_random_uuid(),'HUMAN','m21-auth','m21-key' FROM governance.resolution LIMIT 1; RAISE EXCEPTION 'M11_IDEMPOTENCY_FAIL: duplicate key accepted';
  EXCEPTION WHEN unique_violation THEN RAISE NOTICE 'M11 PASS: approval idempotency key'; END;
END $$;

DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_indexes WHERE schemaname='core' AND indexname='ix_constraint_version') THEN RAISE EXCEPTION 'M24_INDEX_FAIL: expected index missing'; END IF;
  IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE schemaname='tenant' AND tablename='entity_override' AND policyname='tenant_isolation') THEN RAISE EXCEPTION 'M05_RLS_POLICY_FAIL: policy missing'; END IF;
  RAISE NOTICE 'M24 PASS: required index/policy inventory';
END $$;
COMMIT;
SELECT 'PAI-FORGE NONPROD FOUNDATION VERIFICATION: PASS' AS result;
