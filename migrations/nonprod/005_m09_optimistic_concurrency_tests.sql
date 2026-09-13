-- PAI-FORGE M09 OPTIMISTIC CONCURRENCY NONPROD TEST
-- Disposable PostgreSQL 16 only. Never production.
-- Purpose: verify stale-state rejection and atomic compare-and-set behavior.

BEGIN;
DO $$
BEGIN
 IF current_database() <> 'paiforge_test' THEN RAISE EXCEPTION 'NONPROD_TARGET_GUARD: expected database paiforge_test, got %', current_database(); END IF;
 IF current_user <> 'test_admin' THEN RAISE EXCEPTION 'NONPROD_TARGET_GUARD: expected user test_admin, got %', current_user; END IF;
END $$;

CREATE TEMP TABLE m09_results(test_id text PRIMARY KEY, result text, detail text);

DO $$
DECLARE
 v_design uuid;
 v_ds1 uuid;
 v_ds2 uuid;
 v_cr uuid;
 v_actor uuid := gen_random_uuid();
 v_other uuid := gen_random_uuid();
 v_result text;
BEGIN
 v_design := gen_random_uuid();
 INSERT INTO governance.design_state(design_id,state_version,state_hash,ruleset_version,created_by)
 VALUES(v_design,1,'m09-hash-v1','m09-r1',v_actor) RETURNING design_state_id INTO v_ds1;
 INSERT INTO governance.design_state(design_id,state_version,state_hash,ruleset_version,created_by)
 VALUES(v_design,2,'m09-hash-v2','m09-r1',v_actor) RETURNING design_state_id INTO v_ds2;

 INSERT INTO governance.change_request(request_key,design_state_id,expected_state_version,canonical_request_hash,status,created_by)
 VALUES('m09-cr-001',v_ds1,1,'m09-request-001','CANDIDATE',v_actor) RETURNING change_request_id INTO v_cr;

 -- P01: current-state compare-and-set succeeds with exact expected version/hash.
 PERFORM governance.transition_change_request('m09-cr-001','VERIFIED','1','m09-hash-v1','m09-request-001',v_actor::text,'m09-p01');
 SELECT status INTO v_result FROM governance.change_request WHERE change_request_id=v_cr;
 IF v_result <> 'VERIFIED' THEN RAISE EXCEPTION 'M09_P01_UNEXPECTED_STATUS:%',v_result; END IF;
 INSERT INTO m09_results VALUES('M09-P01','PASS','Exact expected state accepted');

 -- P02: stale version/hash must be rejected after the design advances.
 BEGIN
   PERFORM governance.transition_change_request('m09-cr-001','APPROVED','1','m09-hash-v1','m09-request-001',v_actor::text,'m09-p02');
   RAISE EXCEPTION 'M09_P02_EXPECTED_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM LIKE 'M09_P02_EXPECTED_REJECTION_NOT_RAISED%' THEN RAISE; END IF;
   INSERT INTO m09_results VALUES('M09-P02','PASS','Stale expected version/hash rejected: '||SQLERRM);
 END;

 -- N01: an illegal lifecycle transition is rejected, not silently accepted.
 BEGIN
   PERFORM governance.transition_change_request('m09-cr-001','CANDIDATE','1','m09-hash-v1','m09-request-001',v_actor::text,'m09-n01');
   RAISE EXCEPTION 'M09_N01_EXPECTED_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM LIKE 'M09_N01_EXPECTED_REJECTION_NOT_RAISED%' THEN RAISE; END IF;
   INSERT INTO m09_results VALUES('M09-N01','PASS','Illegal transition rejected: '||SQLERRM);
 END;

 -- N02: same idempotency key cannot be reused for a different transition.
 BEGIN
   PERFORM governance.transition_change_request('m09-cr-001','VERIFIED','2','m09-hash-v2','m09-request-001',v_other::text,'m09-p01');
   RAISE EXCEPTION 'M09_N02_EXPECTED_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM LIKE 'M09_N02_EXPECTED_REJECTION_NOT_RAISED%' THEN RAISE; END IF;
   INSERT INTO m09_results VALUES('M09-N02','PASS','Idempotency/replay conflict rejected: '||SQLERRM);
 END;

 -- N03: direct UPDATE remains blocked after enforcement.
 BEGIN
   UPDATE governance.change_request SET status='APPROVED' WHERE change_request_id=v_cr;
   RAISE EXCEPTION 'M09_N03_EXPECTED_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM LIKE 'M09_N03_EXPECTED_REJECTION_NOT_RAISED%' THEN RAISE; END IF;
   INSERT INTO m09_results VALUES('M09-N03','PASS','Direct lifecycle UPDATE rejected: '||SQLERRM);
 END;

 -- N04: transaction rollback must leave state unchanged.
 BEGIN
   SAVEPOINT m09_rollback;
   BEGIN
     PERFORM governance.transition_change_request('m09-cr-001','APPROVED','1','m09-hash-v1','m09-request-001',v_actor::text,'m09-n04');
   EXCEPTION WHEN OTHERS THEN NULL;
   END;
   ROLLBACK TO SAVEPOINT m09_rollback;
   SELECT status INTO v_result FROM governance.change_request WHERE change_request_id=v_cr;
   IF v_result <> 'VERIFIED' THEN RAISE EXCEPTION 'M09_N04_STATE_CHANGED:%',v_result; END IF;
   INSERT INTO m09_results VALUES('M09-N04','PASS','Rejected transition did not mutate state');
 END;

 -- P03: exact expected current state remains sufficient for the next legal transition.
 PERFORM governance.transition_change_request('m09-cr-001','APPROVED','1','m09-hash-v1','m09-request-001',v_actor::text,'m09-p03');
 SELECT status INTO v_result FROM governance.change_request WHERE change_request_id=v_cr;
 IF v_result <> 'APPROVED' THEN RAISE EXCEPTION 'M09_P03_UNEXPECTED_STATUS:%',v_result; END IF;
 INSERT INTO m09_results VALUES('M09-P03','PASS','Controlled transition remains atomic after rejected attempts');
END $$;

SELECT test_id,result,detail FROM m09_results ORDER BY test_id;

DO $$
DECLARE v_blocked int;
BEGIN
 SELECT count(*) INTO v_blocked FROM m09_results WHERE result <> 'PASS';
 IF v_blocked > 0 THEN RAISE EXCEPTION 'M09 OVERALL: BLOCKED (% failed/blocked)',v_blocked; END IF;
 RAISE NOTICE 'M09 OVERALL: PASS';
END $$;

ROLLBACK;
