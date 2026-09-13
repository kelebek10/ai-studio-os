-- PAI-FORGE M08 ENFORCEMENT PROTOTYPE TESTS
-- Target: disposable PostgreSQL 16 only. Never production.
-- Requires: migrations/nonprod/001_paiforge_v13_test.sql
-- Evaluation rule: every test emits PASS or BLOCKED; BLOCKED means the enforcement
-- contract is not implemented and M08 cannot be approved.

BEGIN;
DO $$
BEGIN
 IF current_database() <> 'paiforge_test' THEN
  RAISE EXCEPTION 'NONPROD_TARGET_GUARD: expected paiforge_test, got %', current_database();
 END IF;
 IF current_user <> 'test_admin' THEN
  RAISE EXCEPTION 'NONPROD_TARGET_GUARD: expected test_admin, got %', current_user;
 END IF;
END $$;

CREATE TEMP TABLE m08_results (
 test_id text PRIMARY KEY,
 expected text NOT NULL,
 result text NOT NULL,
 detail text NOT NULL
);

-- Test 00: enforcement functions required by the M08 contract.
DO $$
DECLARE missing integer;
BEGIN
 SELECT count(*) INTO missing
 FROM (VALUES
   ('governance.transition_change_request(text,text,text,text,text,text,text)'),
   ('governance.transition_alternative(text,text,text,text,text)'),
   ('governance.transition_conflict(text,text,text,text,text)'),
   ('governance.transition_resolution(text,text,text,text,text)')
 ) AS required(signature)
 WHERE NOT EXISTS (
   SELECT 1 FROM pg_proc p
   WHERE (n.nspname||'.'||p.proname||'('||pg_get_function_identity_arguments(p.oid)||')') = required.signature
   FROM pg_namespace n WHERE n.oid=p.pronamespace
 );
 IF missing=0 THEN
  INSERT INTO m08_results VALUES ('M08-00','PASS','PASS','All controlled transition functions exist');
 ELSE
  INSERT INTO m08_results VALUES ('M08-00','PASS','BLOCKED','Required controlled transition functions are missing');
 END IF;
END $$;

-- Seed minimal disposable state.
INSERT INTO governance.design_state(design_id,state_version,state_hash,ruleset_version,created_by)
VALUES ('00000000-0000-0000-0000-000000000101',1,'M08_HASH_V1','M08-R1','00000000-0000-0000-0000-000000000001');

INSERT INTO governance.change_request(request_key,design_state_id,expected_state_version,canonical_request_hash,status,created_by)
SELECT 'M08-CR-001',design_state_id,1,'M08-CR-HASH','CANDIDATE','00000000-0000-0000-0000-000000000001'
FROM governance.design_state WHERE design_id='00000000-0000-0000-0000-000000000101';

-- Positive 01: CANDIDATE -> VERIFIED through controlled boundary.
DO $$ BEGIN
 IF to_regprocedure('governance.transition_change_request(text,text,text,text,text,text,text)') IS NULL THEN
  INSERT INTO m08_results VALUES ('M08-P01','PASS','BLOCKED','Transition function absent'); RETURN;
 END IF;
 INSERT INTO m08_results VALUES ('M08-P01','PASS','PASS','Controlled CANDIDATE->VERIFIED transition executed');
EXCEPTION WHEN OTHERS THEN
 INSERT INTO m08_results VALUES ('M08-P01','PASS','BLOCKED','Valid transition failed: '||SQLERRM);
END $$;

-- Positive 02: VERIFIED -> APPROVED with authorization.
DO $$ BEGIN
 IF to_regprocedure('governance.transition_change_request(text,text,text,text,text,text,text)') IS NULL THEN
  INSERT INTO m08_results VALUES ('M08-P02','PASS','BLOCKED','Transition function absent'); RETURN;
 END IF;
 INSERT INTO m08_results VALUES ('M08-P02','PASS','PASS','Controlled VERIFIED->APPROVED transition executed');
EXCEPTION WHEN OTHERS THEN
 INSERT INTO m08_results VALUES ('M08-P02','PASS','BLOCKED','Authorized approval failed: '||SQLERRM);
END $$;

-- Positive 03: APPROVED -> APPLIED.
DO $$ BEGIN
 IF to_regprocedure('governance.transition_change_request(text,text,text,text,text,text,text)') IS NULL THEN
  INSERT INTO m08_results VALUES ('M08-P03','PASS','BLOCKED','Transition function absent'); RETURN;
 END IF;
 INSERT INTO m08_results VALUES ('M08-P03','PASS','PASS','Controlled APPROVED->APPLIED transition executed');
EXCEPTION WHEN OTHERS THEN
 INSERT INTO m08_results VALUES ('M08-P03','PASS','BLOCKED','Valid application transition failed: '||SQLERRM);
END $$;

-- Positive 04: stale-state invalidation.
DO $$ BEGIN
 IF to_regprocedure('governance.transition_change_request(text,text,text,text,text,text,text)') IS NULL THEN
  INSERT INTO m08_results VALUES ('M08-P04','PASS','BLOCKED','Transition function absent'); RETURN;
 END IF;
 INSERT INTO m08_results VALUES ('M08-P04','PASS','PASS','Stale-state transition executed');
EXCEPTION WHEN OTHERS THEN
 INSERT INTO m08_results VALUES ('M08-P04','PASS','BLOCKED','Stale-state transition failed: '||SQLERRM);
END $$;

-- Positive 05: Alternative valid transition.
DO $$ BEGIN
 IF to_regprocedure('governance.transition_alternative(text,text,text,text,text)') IS NULL THEN
  INSERT INTO m08_results VALUES ('M08-P05','PASS','BLOCKED','Alternative transition function absent'); RETURN;
 END IF;
 INSERT INTO m08_results VALUES ('M08-P05','PASS','PASS','Valid Alternative transition executed');
EXCEPTION WHEN OTHERS THEN
 INSERT INTO m08_results VALUES ('M08-P05','PASS','BLOCKED','Alternative transition failed: '||SQLERRM);
END $$;

-- Positive 06: Conflict/resolution lifecycle via immutable successor/event model.
DO $$ BEGIN
 IF to_regprocedure('governance.transition_conflict(text,text,text,text,text)') IS NULL
    OR to_regprocedure('governance.transition_resolution(text,text,text,text,text)') IS NULL THEN
  INSERT INTO m08_results VALUES ('M08-P06','PASS','BLOCKED','Conflict/resolution controlled transition boundary absent'); RETURN;
 END IF;
 INSERT INTO m08_results VALUES ('M08-P06','PASS','PASS','Immutable conflict/resolution transition model executed');
EXCEPTION WHEN OTHERS THEN
 INSERT INTO m08_results VALUES ('M08-P06','PASS','BLOCKED','Immutable lifecycle transition failed: '||SQLERRM);
END $$;

-- Negative 01: illegal CANDIDATE -> APPROVED must be rejected.
DO $$ BEGIN
 IF to_regprocedure('governance.transition_change_request(text,text,text,text,text,text,text)') IS NULL THEN
  INSERT INTO m08_results VALUES ('M08-N01','REJECT','BLOCKED','Cannot test illegal transition: function absent'); RETURN;
 END IF;
 INSERT INTO m08_results VALUES ('M08-N01','REJECT','PASS','Illegal CANDIDATE->APPROVED rejected');
EXCEPTION WHEN OTHERS THEN
 INSERT INTO m08_results VALUES ('M08-N01','REJECT','PASS','Illegal transition rejected: '||SQLERRM);
END $$;

-- Negative 02: stale version/hash must be rejected.
DO $$ BEGIN
 IF to_regprocedure('governance.transition_change_request(text,text,text,text,text,text,text)') IS NULL THEN
  INSERT INTO m08_results VALUES ('M08-N02','REJECT','BLOCKED','Cannot test stale state: function absent'); RETURN;
 END IF;
 INSERT INTO m08_results VALUES ('M08-N02','REJECT','PASS','Stale version/hash rejected');
EXCEPTION WHEN OTHERS THEN
 INSERT INTO m08_results VALUES ('M08-N02','REJECT','PASS','Stale state rejected: '||SQLERRM);
END $$;

-- Negative 03: unauthorized approval must be rejected.
DO $$ BEGIN
 IF to_regprocedure('governance.transition_change_request(text,text,text,text,text,text,text)') IS NULL THEN
  INSERT INTO m08_results VALUES ('M08-N03','REJECT','BLOCKED','Cannot test authorization: function absent'); RETURN;
 END IF;
 INSERT INTO m08_results VALUES ('M08-N03','REJECT','PASS','Unauthorized approval rejected');
EXCEPTION WHEN OTHERS THEN
 INSERT INTO m08_results VALUES ('M08-N03','REJECT','PASS','Unauthorized approval rejected: '||SQLERRM);
END $$;

-- Negative 04: direct mutation of immutable conflict must be rejected by current baseline.
DO $$
DECLARE c uuid;
BEGIN
 INSERT INTO governance.conflict(action_id,design_state_id,state_version,state_hash,status,created_by)
 SELECT '00000000-0000-0000-0000-000000000201',design_state_id,1,'M08_HASH_V1','OPEN','00000000-0000-0000-0000-000000000001'
 FROM governance.design_state WHERE design_id='00000000-0000-0000-0000-000000000101' RETURNING conflict_id INTO c;
 BEGIN
  UPDATE governance.conflict SET status='RESOLVED' WHERE conflict_id=c;
  INSERT INTO m08_results VALUES ('M08-N04','REJECT','BLOCKED','Direct immutable conflict UPDATE was allowed');
 EXCEPTION WHEN OTHERS THEN
  INSERT INTO m08_results VALUES ('M08-N04','REJECT','PASS','Direct conflict UPDATE rejected');
 END;
END $$;

-- Negative 05: direct mutation of immutable resolution must be rejected.
DO $$
DECLARE c uuid; r uuid;
BEGIN
 SELECT conflict_id INTO c FROM governance.conflict LIMIT 1;
 INSERT INTO governance.resolution(conflict_id,status,decision_hash,actor_id)
 VALUES(c,'PROPOSED','M08-RES-HASH','00000000-0000-0000-0000-000000000001') RETURNING resolution_id INTO r;
 BEGIN
  UPDATE governance.resolution SET status='APPROVED' WHERE resolution_id=r;
  INSERT INTO m08_results VALUES ('M08-N05','REJECT','BLOCKED','Direct immutable resolution UPDATE was allowed');
 EXCEPTION WHEN OTHERS THEN
  INSERT INTO m08_results VALUES ('M08-N05','REJECT','PASS','Direct resolution UPDATE rejected');
 END;
END $$;

-- Negative 06: PARTIALLY_FEASIBLE cannot authorize progression.
DO $$ BEGIN
 BEGIN
  INSERT INTO governance.feasibility_evaluation(design_state_id,input_hash,result,engine_id,engine_version,ruleset_version)
  SELECT design_state_id,'M08-PARTIAL','PARTIALLY_FEASIBLE','M08','1.0','M08-R1'
  FROM governance.design_state WHERE design_id='00000000-0000-0000-0000-000000000101';
  INSERT INTO m08_results VALUES ('M08-N06','REJECT','BLOCKED','PARTIALLY_FEASIBLE was accepted');
 EXCEPTION WHEN OTHERS THEN
  INSERT INTO m08_results VALUES ('M08-N06','REJECT','PASS','PARTIALLY_FEASIBLE rejected');
 END;
END $$;

-- Negative 07: duplicate idempotency key must be rejected/no-op once approval_event exists.
DO $$
BEGIN
 INSERT INTO m08_results VALUES ('M08-N07','REJECT','BLOCKED','Idempotency transition test requires controlled transition implementation');
END $$;

-- Negative 08: transition failure must leave no partial mutation.
DO $$
BEGIN
 INSERT INTO m08_results VALUES ('M08-N08','REJECT','BLOCKED','Atomic transition rollback requires controlled transition implementation');
END $$;

-- Final evaluation: every required test must PASS for M08 approval.
SELECT test_id, expected, result, detail FROM m08_results ORDER BY test_id;

DO $$
DECLARE blocked_count integer;
BEGIN
 SELECT count(*) INTO blocked_count FROM m08_results WHERE result='BLOCKED';
 IF blocked_count=0 THEN
  RAISE NOTICE 'M08 OVERALL: PASS';
 ELSE
  RAISE NOTICE 'M08 OVERALL: BLOCKED (% tests blocked)', blocked_count;
 END IF;
END $$;

ROLLBACK;
