-- PAI-FORGE M08 ENFORCEMENT PROTOTYPE TESTS v1.1
-- Target: disposable PostgreSQL 16 only. Never production.
-- Requires: migrations/nonprod/001_paiforge_v13_test.sql
-- IMPORTANT: this file tests an implemented enforcement prototype; it never fabricates PASS.
-- Any missing enforcement capability is reported as BLOCKED.

BEGIN;
DO $$
BEGIN
 IF current_database() <> 'paiforge_test' THEN RAISE EXCEPTION 'NONPROD_TARGET_GUARD: expected paiforge_test, got %',current_database(); END IF;
 IF current_user <> 'test_admin' THEN RAISE EXCEPTION 'NONPROD_TARGET_GUARD: expected test_admin, got %',current_user; END IF;
END $$;

CREATE TEMP TABLE m08_results(test_id text PRIMARY KEY, result text NOT NULL, detail text NOT NULL);

-- M08-00: required controlled boundaries must exist.
DO $$
DECLARE missing text='';
BEGIN
 IF to_regprocedure('governance.transition_change_request(text,text,text,text,text,text,text)') IS NULL THEN missing:=missing||' change_request'; END IF;
 IF to_regprocedure('governance.transition_alternative(text,text,text,text,text)') IS NULL THEN missing:=missing||' alternative'; END IF;
 IF to_regprocedure('governance.transition_conflict(text,text,text,text,text)') IS NULL THEN missing:=missing||' conflict'; END IF;
 IF to_regprocedure('governance.transition_resolution(text,text,text,text,text)') IS NULL THEN missing:=missing||' resolution'; END IF;
 INSERT INTO m08_results VALUES('M08-00',CASE WHEN missing='' THEN 'PASS' ELSE 'BLOCKED' END,CASE WHEN missing='' THEN 'All controlled transition functions exist' ELSE 'Missing:'||missing END);
END $$;

-- Seed immutable design state and change request.
INSERT INTO governance.design_state(design_id,state_version,state_hash,ruleset_version,created_by)
VALUES('00000000-0000-0000-0000-000000000101',1,'M08_HASH_V1','M08-R1','00000000-0000-0000-0000-000000000001');
INSERT INTO governance.change_request(request_key,design_state_id,expected_state_version,canonical_request_hash,status,created_by)
SELECT 'M08-CR-001',design_state_id,1,'M08-CR-HASH','CANDIDATE','00000000-0000-0000-0000-000000000001'
FROM governance.design_state WHERE design_id='00000000-0000-0000-0000-000000000101';

-- Positive transition tests. Exact function invocation is intentionally gated by existence.
DO $$
DECLARE id text;
BEGIN
 IF to_regprocedure('governance.transition_change_request(text,text,text,text,text,text,text)') IS NULL THEN
  INSERT INTO m08_results VALUES('M08-P01','BLOCKED','Missing transition_change_request'); RETURN;
 END IF;
 BEGIN
  EXECUTE 'SELECT governance.transition_change_request($1,$2,$3,$4,$5,$6,$7)' USING 'M08-CR-001','CANDIDATE','VERIFIED','1','M08_HASH_V1','M08-CR-HASH','00000000-0000-0000-0000-000000000001';
  SELECT status INTO id FROM governance.change_request WHERE request_key='M08-CR-001';
  INSERT INTO m08_results VALUES('M08-P01',CASE WHEN id='VERIFIED' THEN 'PASS' ELSE 'BLOCKED' END,'Expected VERIFIED, observed '||coalesce(id,'NULL'));
 EXCEPTION WHEN OTHERS THEN INSERT INTO m08_results VALUES('M08-P01','BLOCKED','Valid CANDIDATE->VERIFIED failed: '||SQLERRM); END;
END $$;

DO $$
DECLARE s text;
BEGIN
 IF to_regprocedure('governance.transition_change_request(text,text,text,text,text,text,text)') IS NULL THEN INSERT INTO m08_results VALUES('M08-P02','BLOCKED','Missing transition_change_request'); RETURN; END IF;
 BEGIN
  EXECUTE 'SELECT governance.transition_change_request($1,$2,$3,$4,$5,$6,$7)' USING 'M08-CR-001','VERIFIED','APPROVED','1','M08_HASH_V1','M08-APPROVAL-001','00000000-0000-0000-0000-000000000001';
  SELECT status INTO s FROM governance.change_request WHERE request_key='M08-CR-001';
  INSERT INTO m08_results VALUES('M08-P02',CASE WHEN s='APPROVED' THEN 'PASS' ELSE 'BLOCKED' END,'Expected APPROVED, observed '||coalesce(s,'NULL'));
 EXCEPTION WHEN OTHERS THEN INSERT INTO m08_results VALUES('M08-P02','BLOCKED','Authorized approval failed: '||SQLERRM); END;
END $$;

DO $$
DECLARE s text;
BEGIN
 IF to_regprocedure('governance.transition_change_request(text,text,text,text,text,text,text)') IS NULL THEN INSERT INTO m08_results VALUES('M08-P03','BLOCKED','Missing transition_change_request'); RETURN; END IF;
 BEGIN
  EXECUTE 'SELECT governance.transition_change_request($1,$2,$3,$4,$5,$6,$7)' USING 'M08-CR-001','APPROVED','APPLIED','1','M08_HASH_V1','M08-APPLY-001','00000000-0000-0000-0000-000000000001';
  SELECT status INTO s FROM governance.change_request WHERE request_key='M08-CR-001';
  INSERT INTO m08_results VALUES('M08-P03',CASE WHEN s='APPLIED' THEN 'PASS' ELSE 'BLOCKED' END,'Expected APPLIED, observed '||coalesce(s,'NULL'));
 EXCEPTION WHEN OTHERS THEN INSERT INTO m08_results VALUES('M08-P03','BLOCKED','Valid APPROVED->APPLIED failed: '||SQLERRM); END;
END $$;

-- Negative illegal transition: fresh candidate cannot jump to APPROVED.
INSERT INTO governance.change_request(request_key,design_state_id,expected_state_version,canonical_request_hash,status,created_by)
SELECT 'M08-CR-N01',design_state_id,1,'M08-N01','CANDIDATE','00000000-0000-0000-0000-000000000001' FROM governance.design_state WHERE design_id='00000000-0000-0000-0000-000000000101';
DO $$
BEGIN
 IF to_regprocedure('governance.transition_change_request(text,text,text,text,text,text,text)') IS NULL THEN INSERT INTO m08_results VALUES('M08-N01','BLOCKED','Missing transition_change_request'); RETURN; END IF;
 BEGIN
  EXECUTE 'SELECT governance.transition_change_request($1,$2,$3,$4,$5,$6,$7)' USING 'M08-CR-N01','CANDIDATE','APPROVED','1','M08_HASH_V1','M08-N01','00000000-0000-0000-0000-000000000001';
  INSERT INTO m08_results VALUES('M08-N01','BLOCKED','Illegal CANDIDATE->APPROVED was accepted');
 EXCEPTION WHEN OTHERS THEN INSERT INTO m08_results VALUES('M08-N01','PASS','Illegal transition rejected: '||SQLERRM); END;
END $$;

-- Negative stale hash/version.
DO $$
BEGIN
 IF to_regprocedure('governance.transition_change_request(text,text,text,text,text,text,text)') IS NULL THEN INSERT INTO m08_results VALUES('M08-N02','BLOCKED','Missing transition_change_request'); RETURN; END IF;
 BEGIN
  EXECUTE 'SELECT governance.transition_change_request($1,$2,$3,$4,$5,$6,$7)' USING 'M08-CR-N01','CANDIDATE','VERIFIED','99','WRONG_HASH','M08-N02','00000000-0000-0000-0000-000000000001';
  INSERT INTO m08_results VALUES('M08-N02','BLOCKED','Stale version/hash was accepted');
 EXCEPTION WHEN OTHERS THEN INSERT INTO m08_results VALUES('M08-N02','PASS','Stale version/hash rejected: '||SQLERRM); END;
END $$;

-- Immutable conflict direct UPDATE must remain rejected.
DO $$ DECLARE c uuid;
BEGIN
 INSERT INTO governance.conflict(action_id,design_state_id,state_version,state_hash,status,created_by)
 SELECT '00000000-0000-0000-0000-000000000201',design_state_id,1,'M08_HASH_V1','OPEN','00000000-0000-0000-0000-000000000001' FROM governance.design_state WHERE design_id='00000000-0000-0000-0000-000000000101' RETURNING conflict_id INTO c;
 BEGIN UPDATE governance.conflict SET status='RESOLVED' WHERE conflict_id=c; INSERT INTO m08_results VALUES('M08-N03','BLOCKED','Direct conflict UPDATE was allowed'); EXCEPTION WHEN OTHERS THEN INSERT INTO m08_results VALUES('M08-N03','PASS','Direct conflict UPDATE rejected'); END;
END $$;

-- Immutable resolution direct UPDATE must remain rejected.
DO $$ DECLARE c uuid; r uuid;
BEGIN
 SELECT conflict_id INTO c FROM governance.conflict LIMIT 1;
 INSERT INTO governance.resolution(conflict_id,status,decision_hash,actor_id) VALUES(c,'PROPOSED','M08-RES','00000000-0000-0000-0000-000000000001') RETURNING resolution_id INTO r;
 BEGIN UPDATE governance.resolution SET status='APPROVED' WHERE resolution_id=r; INSERT INTO m08_results VALUES('M08-N04','BLOCKED','Direct resolution UPDATE was allowed'); EXCEPTION WHEN OTHERS THEN INSERT INTO m08_results VALUES('M08-N04','PASS','Direct resolution UPDATE rejected'); END;
END $$;

-- PARTIALLY_FEASIBLE rejection.
DO $$
BEGIN
 BEGIN
  INSERT INTO governance.feasibility_evaluation(design_state_id,input_hash,result,engine_id,engine_version,ruleset_version)
  SELECT design_state_id,'M08-PARTIAL','PARTIALLY_FEASIBLE','M08','1.0','M08-R1' FROM governance.design_state WHERE design_id='00000000-0000-0000-0000-000000000101';
  INSERT INTO m08_results VALUES('M08-N05','BLOCKED','PARTIALLY_FEASIBLE was accepted');
 EXCEPTION WHEN OTHERS THEN INSERT INTO m08_results VALUES('M08-N05','PASS','PARTIALLY_FEASIBLE rejected'); END;
END $$;

-- Overall gate.
SELECT test_id,result,detail FROM m08_results ORDER BY test_id;
DO $$ DECLARE blocked integer;
BEGIN SELECT count(*) INTO blocked FROM m08_results WHERE result='BLOCKED'; IF blocked=0 THEN RAISE NOTICE 'M08 OVERALL: PASS'; ELSE RAISE NOTICE 'M08 OVERALL: BLOCKED (% blocked)',blocked; END IF; END $$;
ROLLBACK;
