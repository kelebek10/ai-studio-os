-- PAI-FORGE M09 OPTIMISTIC CONCURRENCY NONPROD TEST
-- Disposable PostgreSQL 16 only. Never production.
-- Scope: compare-and-set / stale-state / idempotency / mutation isolation.

BEGIN;
DO $$
BEGIN
 IF current_database() <> 'paiforge_test' THEN RAISE EXCEPTION 'NONPROD_TARGET_GUARD: expected database paiforge_test, got %', current_database(); END IF;
 IF current_user <> 'test_admin' THEN RAISE EXCEPTION 'NONPROD_TARGET_GUARD: expected user test_admin, got %', current_user; END IF;
END $$;

CREATE TEMP TABLE m09_results(test_id text PRIMARY KEY, result text, detail text);

DO $$
DECLARE
 v_design uuid := gen_random_uuid();
 v_ds1 uuid;
 v_cr uuid;
 v_actor uuid := gen_random_uuid();
 v_other uuid := gen_random_uuid();
 v_result text;
BEGIN
 INSERT INTO governance.design_state(design_id,state_version,state_hash,ruleset_version,created_by)
 VALUES(v_design,1,'m09-hash-v1','m09-r1',v_actor) RETURNING design_state_id INTO v_ds1;
 INSERT INTO governance.change_request(request_key,design_state_id,expected_state_version,canonical_request_hash,status,created_by)
 VALUES('m09-cr-001',v_ds1,1,'m09-request-001','CANDIDATE',v_actor) RETURNING change_request_id INTO v_cr;

 -- P01: exact compare-and-set succeeds.
 PERFORM governance.transition_change_request('m09-cr-001','CANDIDATE','VERIFIED','1','m09-hash-v1','m09-p01',v_actor::text);
 SELECT status INTO v_result FROM governance.change_request WHERE change_request_id=v_cr;
 IF v_result <> 'VERIFIED' THEN RAISE EXCEPTION 'M09_P01_UNEXPECTED_STATUS:%',v_result; END IF;
 INSERT INTO m09_results VALUES('M09-P01','PASS','Exact expected version/hash accepted');

 -- P02: exact replay is idempotent.
 PERFORM governance.transition_change_request('m09-cr-001','CANDIDATE','VERIFIED','1','m09-hash-v1','m09-p01',v_other::text);
 SELECT status INTO v_result FROM governance.change_request WHERE change_request_id=v_cr;
 IF v_result <> 'VERIFIED' THEN RAISE EXCEPTION 'M09_P02_UNEXPECTED_STATUS:%',v_result; END IF;
 INSERT INTO m09_results VALUES('M09-P02','PASS','Exact replay returned existing transition without mutation');

 -- N01: stale predecessor/status cannot be reused as a fresh transition.
 BEGIN
   PERFORM governance.transition_change_request('m09-cr-001','CANDIDATE','APPROVED','1','m09-hash-v1','m09-n01',v_actor::text);
   RAISE EXCEPTION 'M09_N01_EXPECTED_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM LIKE 'M09_N01_EXPECTED_REJECTION_NOT_RAISED%' THEN RAISE; END IF;
   INSERT INTO m09_results VALUES('M09-N01','PASS','Stale predecessor rejected: '||SQLERRM);
 END;

 -- N02: stale state version/hash rejected before transition.
 BEGIN
   PERFORM governance.transition_change_request('m09-cr-001','VERIFIED','APPROVED','0','wrong-hash','m09-n02',v_actor::text);
   RAISE EXCEPTION 'M09_N02_EXPECTED_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM LIKE 'M09_N02_EXPECTED_REJECTION_NOT_RAISED%' THEN RAISE; END IF;
   IF SQLERRM NOT LIKE 'STALE_STATE_VERSION%' AND SQLERRM NOT LIKE 'STALE_STATE_HASH%' THEN RAISE EXCEPTION 'M09_N02_WRONG_ERROR:%',SQLERRM; END IF;
   INSERT INTO m09_results VALUES('M09-N02','PASS','Stale version/hash rejected: '||SQLERRM);
 END;

 -- N03: same canonical identity cannot be reused for a different transition.
 BEGIN
   PERFORM governance.transition_change_request('m09-cr-001','VERIFIED','APPROVED','1','m09-hash-v1','m09-p01',v_other::text);
   RAISE EXCEPTION 'M09_N03_EXPECTED_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM LIKE 'M09_N03_EXPECTED_REJECTION_NOT_RAISED%' THEN RAISE; END IF;
   INSERT INTO m09_results VALUES('M09-N03','PASS','Conflicting canonical replay rejected: '||SQLERRM);
 END;

 -- N04: direct UPDATE remains blocked.
 BEGIN
   UPDATE governance.change_request SET status='APPROVED' WHERE change_request_id=v_cr;
   RAISE EXCEPTION 'M09_N04_EXPECTED_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM LIKE 'M09_N04_EXPECTED_REJECTION_NOT_RAISED%' THEN RAISE; END IF;
   INSERT INTO m09_results VALUES('M09-N04','PASS','Direct lifecycle UPDATE rejected: '||SQLERRM);
 END;

 -- N05: rejected transition attempts do not mutate persisted state.
 BEGIN
   PERFORM governance.transition_change_request('m09-cr-001','VERIFIED','APPLIED','1','m09-hash-v1','m09-n05',v_actor::text);
   RAISE EXCEPTION 'M09_N05_EXPECTED_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM LIKE 'M09_N05_EXPECTED_REJECTION_NOT_RAISED%' THEN RAISE; END IF;
   SELECT status INTO v_result FROM governance.change_request WHERE change_request_id=v_cr;
   IF v_result <> 'VERIFIED' THEN RAISE EXCEPTION 'M09_N05_STATE_MUTATED:%',v_result; END IF;
   INSERT INTO m09_results VALUES('M09-N05','PASS','Rejected transition left state unchanged: '||SQLERRM);
 END;

 -- P03: valid next transition succeeds after rejected attempts.
 PERFORM governance.transition_change_request('m09-cr-001','VERIFIED','APPROVED','1','m09-hash-v1','m09-p03',v_actor::text);
 SELECT status INTO v_result FROM governance.change_request WHERE change_request_id=v_cr;
 IF v_result <> 'APPROVED' THEN RAISE EXCEPTION 'M09_P03_UNEXPECTED_STATUS:%',v_result; END IF;
 INSERT INTO m09_results VALUES('M09-P03','PASS','Valid transition remains atomic after rejected attempts');
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
