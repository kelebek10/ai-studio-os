-- PAI-FORGE M09 OPTIMISTIC CONCURRENCY NONPROD TEST v1.1
-- Disposable PostgreSQL 16 only. Never production.
-- M09 deliberately verifies both working CAS guards and architectural gaps.

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
 v_ds2 uuid;
 v_cr uuid;
 v_cr_stale uuid;
 v_actor uuid := gen_random_uuid();
 v_other uuid := gen_random_uuid();
 v_result text;
 v_event1 uuid;
 v_event2 uuid;
BEGIN
 INSERT INTO governance.design_state(design_id,state_version,state_hash,ruleset_version,created_by)
 VALUES(v_design,1,'m09-hash-v1','m09-r1',v_actor) RETURNING design_state_id INTO v_ds1;
 INSERT INTO governance.design_state(design_id,state_version,state_hash,ruleset_version,created_by)
 VALUES(v_design,2,'m09-hash-v2','m09-r1',v_actor) RETURNING design_state_id INTO v_ds2;

 INSERT INTO governance.change_request(request_key,design_state_id,expected_state_version,canonical_request_hash,status,created_by)
 VALUES('m09-cr-001',v_ds1,1,'m09-request-001','CANDIDATE',v_actor) RETURNING change_request_id INTO v_cr;
 INSERT INTO governance.change_request(request_key,design_state_id,expected_state_version,canonical_request_hash,status,created_by)
 VALUES('m09-cr-stale',v_ds2,2,'m09-request-stale','CANDIDATE',v_actor) RETURNING change_request_id INTO v_cr_stale;

 -- P01: exact expected version/hash succeeds.
 v_event1 := governance.transition_change_request('m09-cr-001','CANDIDATE','VERIFIED','1','m09-hash-v1','m09-p01',v_actor::text);
 SELECT status INTO v_result FROM governance.change_request WHERE change_request_id=v_cr;
 IF v_result <> 'VERIFIED' THEN RAISE EXCEPTION 'M09_P01_UNEXPECTED_STATUS:%',v_result; END IF;
 INSERT INTO m09_results VALUES('M09-P01','PASS','Exact expected version/hash accepted');

 -- P02: stale expected version is rejected.
 BEGIN
   PERFORM governance.transition_change_request('m09-cr-stale','CANDIDATE','VERIFIED','1','m09-hash-v1','m09-p02',v_actor::text);
   RAISE EXCEPTION 'M09_P02_EXPECTED_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM LIKE 'M09_P02_EXPECTED_REJECTION_NOT_RAISED%' THEN RAISE; END IF;
   IF SQLERRM NOT LIKE 'STALE_STATE_VERSION%' THEN RAISE EXCEPTION 'M09_P02_WRONG_ERROR:%',SQLERRM; END IF;
   INSERT INTO m09_results VALUES('M09-P02','PASS','Stale expected version rejected: '||SQLERRM);
 END;

 -- P03: stale expected hash is rejected after version is corrected.
 BEGIN
   PERFORM governance.transition_change_request('m09-cr-stale','CANDIDATE','VERIFIED','2','m09-hash-v1','m09-p03',v_actor::text);
   RAISE EXCEPTION 'M09_P03_EXPECTED_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM LIKE 'M09_P03_EXPECTED_REJECTION_NOT_RAISED%' THEN RAISE; END IF;
   IF SQLERRM NOT LIKE 'STALE_STATE_HASH%' THEN RAISE EXCEPTION 'M09_P03_WRONG_ERROR:%',SQLERRM; END IF;
   INSERT INTO m09_results VALUES('M09-P03','PASS','Stale expected hash rejected: '||SQLERRM);
 END;

 -- N01: predecessor/status mismatch is rejected.
 BEGIN
   PERFORM governance.transition_change_request('m09-cr-001','CANDIDATE','APPROVED','1','m09-hash-v1','m09-n01',v_actor::text);
   RAISE EXCEPTION 'M09_N01_EXPECTED_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM LIKE 'M09_N01_EXPECTED_REJECTION_NOT_RAISED%' THEN RAISE; END IF;
   IF SQLERRM NOT LIKE 'INVALID_PREDECESSOR_STATE%' THEN RAISE EXCEPTION 'M09_N01_WRONG_ERROR:%',SQLERRM; END IF;
   INSERT INTO m09_results VALUES('M09-N01','PASS','Predecessor mismatch rejected: '||SQLERRM);
 END;

 -- N02: direct lifecycle UPDATE remains blocked.
 BEGIN
   UPDATE governance.change_request SET status='APPROVED' WHERE change_request_id=v_cr;
   RAISE EXCEPTION 'M09_N02_EXPECTED_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM LIKE 'M09_N02_EXPECTED_REJECTION_NOT_RAISED%' THEN RAISE; END IF;
   IF SQLERRM NOT LIKE 'DIRECT_MUTATION_BLOCKED%' THEN RAISE EXCEPTION 'M09_N02_WRONG_ERROR:%',SQLERRM; END IF;
   INSERT INTO m09_results VALUES('M09-N02','PASS','Direct lifecycle UPDATE rejected: '||SQLERRM);
 END;

 -- N03: rejected transition attempts do not mutate persisted state.
 BEGIN
   PERFORM governance.transition_change_request('m09-cr-001','VERIFIED','APPLIED','1','m09-hash-v1','m09-n03',v_actor::text);
   RAISE EXCEPTION 'M09_N03_EXPECTED_REJECTION_NOT_RAISED';
 EXCEPTION WHEN OTHERS THEN
   IF SQLERRM LIKE 'M09_N03_EXPECTED_REJECTION_NOT_RAISED%' THEN RAISE; END IF;
   SELECT status INTO v_result FROM governance.change_request WHERE change_request_id=v_cr;
   IF v_result <> 'VERIFIED' THEN RAISE EXCEPTION 'M09_N03_STATE_MUTATED:%',v_result; END IF;
   INSERT INTO m09_results VALUES('M09-N03','PASS','Rejected transition left state unchanged: '||SQLERRM);
 END;

 -- N04: exact replay currently exposes an M08 idempotency-ordering defect.
 BEGIN
   v_event2 := governance.transition_change_request('m09-cr-001','CANDIDATE','VERIFIED','1','m09-hash-v1','m09-p01',v_other::text);
   IF v_event2 <> v_event1 THEN RAISE EXCEPTION 'M09_N04_EVENT_ID_CHANGED'; END IF;
   SELECT status INTO v_result FROM governance.change_request WHERE change_request_id=v_cr;
   IF v_result <> 'VERIFIED' THEN RAISE EXCEPTION 'M09_N04_STATE_CHANGED:%',v_result; END IF;
   INSERT INTO m09_results VALUES('M09-N04','PASS','Replay returned same event and preserved state');
 EXCEPTION WHEN OTHERS THEN
   INSERT INTO m09_results VALUES('M09-N04','BLOCKED','Idempotent replay failed before replay lookup: '||SQLERRM);
 END;

 -- N05: true two-writer optimistic CAS boundary must exist; current M08 prototype has no design-head CAS boundary.
 IF to_regclass('governance.design_head') IS NULL
    AND to_regprocedure('governance.compare_and_set_design_head(uuid,bigint,text)') IS NULL THEN
   INSERT INTO m09_results VALUES('M09-N05','BLOCKED','No design-head/CAS boundary exists; true concurrent two-writer optimistic concurrency is not yet enforceable');
 ELSE
   INSERT INTO m09_results VALUES('M09-N05','PASS','Design-head/CAS boundary detected');
 END IF;

 -- P04: valid next transition still succeeds after rejected checks.
 PERFORM governance.transition_change_request('m09-cr-001','VERIFIED','APPROVED','1','m09-hash-v1','m09-p04',v_actor::text);
 SELECT status INTO v_result FROM governance.change_request WHERE change_request_id=v_cr;
 IF v_result <> 'APPROVED' THEN RAISE EXCEPTION 'M09_P04_UNEXPECTED_STATUS:%',v_result; END IF;
 INSERT INTO m09_results VALUES('M09-P04','PASS','Valid transition remains atomic after rejected attempts');
END $$;

SELECT test_id,result,detail FROM m09_results ORDER BY test_id;

DO $$
DECLARE v_blocked int;
BEGIN
 SELECT count(*) INTO v_blocked FROM m09_results WHERE result='BLOCKED';
 IF v_blocked > 0 THEN RAISE EXCEPTION 'M09 OVERALL: BLOCKED (% blocking findings)',v_blocked; END IF;
 RAISE NOTICE 'M09 OVERALL: PASS';
END $$;

ROLLBACK;
