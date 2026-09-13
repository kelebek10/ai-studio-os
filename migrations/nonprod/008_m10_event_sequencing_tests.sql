-- PAI-FORGE M10 Event Sequencing tests v1.0
-- Disposable PostgreSQL only. Never production.
-- M10 verifies ordering, replay, immutability and partial-failure behavior.

\set ON_ERROR_STOP on

BEGIN;

DO $$
BEGIN
  IF current_database() <> 'paiforge_test' THEN
    RAISE EXCEPTION 'M10_TEST_GUARD: expected paiforge_test, got %', current_database();
  END IF;
END $$;

CREATE TEMP TABLE m10_results(
  test_id text PRIMARY KEY,
  result text NOT NULL,
  detail text NOT NULL
);

-- M10-00: required event boundary must exist.
DO $$
BEGIN
  IF to_regclass('governance.transition_event') IS NULL THEN
    INSERT INTO m10_results VALUES('M10-00','BLOCKED','governance.transition_event is missing');
  ELSE
    INSERT INTO m10_results VALUES('M10-00','PASS','transition_event exists');
  END IF;
END $$;

-- Seed a fresh design state and change request for this test transaction.
INSERT INTO governance.design_state(design_id,state_version,state_hash,ruleset_version,created_by)
VALUES('00000000-0000-0000-0000-000000001010',1,'M10_HASH_V1','M10-R1','00000000-0000-0000-0000-000000000001');

INSERT INTO governance.change_request(request_key,design_state_id,expected_state_version,canonical_request_hash,status,created_by)
SELECT 'M10-CR-001',design_state_id,1,'M10-CR-HASH','CANDIDATE','00000000-0000-0000-0000-000000000001'
FROM governance.design_state WHERE design_id='00000000-0000-0000-0000-000000001010';

-- M10-P01: controlled transition emits exactly one evidence event.
DO $$
DECLARE ev uuid; cnt integer;
BEGIN
  BEGIN
    ev := governance.transition_change_request(
      'M10-CR-001','CANDIDATE','VERIFIED','1','M10_HASH_V1',
      'M10-SEQ-001','00000000-0000-0000-0000-000000000001');
    SELECT count(*) INTO cnt FROM governance.transition_event
    WHERE entity_type='CHANGE_REQUEST'
      AND entity_id=(SELECT change_request_id FROM governance.change_request WHERE request_key='M10-CR-001');
    INSERT INTO m10_results VALUES('M10-P01',CASE WHEN cnt=1 THEN 'PASS' ELSE 'BLOCKED' END,
      'Controlled transition emitted exactly one event; count='||cnt);
  EXCEPTION WHEN OTHERS THEN
    INSERT INTO m10_results VALUES('M10-P01','BLOCKED','Controlled transition failed: '||SQLERRM);
  END;
END $$;

-- M10-N01: predecessor/order mismatch must reject.
DO $$
BEGIN
  BEGIN
    PERFORM governance.transition_change_request(
      'M10-CR-001','CANDIDATE','APPROVED','1','M10_HASH_V1',
      'M10-SEQ-N01','00000000-0000-0000-0000-000000000001');
    INSERT INTO m10_results VALUES('M10-N01','BLOCKED','Invalid predecessor/order was accepted');
  EXCEPTION WHEN OTHERS THEN
    INSERT INTO m10_results VALUES('M10-N01','PASS','Invalid predecessor/order rejected: '||SQLERRM);
  END;
END $$;

-- M10-N02: duplicate canonical identity must replay the same event.
DO $$
DECLARE ev1 uuid; ev2 uuid; cnt integer;
BEGIN
  BEGIN
    ev1 := governance.transition_change_request(
      'M10-CR-001','VERIFIED','APPROVED','1','M10_HASH_V1',
      'M10-SEQ-002','00000000-0000-0000-0000-000000000001');
    ev2 := governance.transition_change_request(
      'M10-CR-001','VERIFIED','APPROVED','1','M10_HASH_V1',
      'M10-SEQ-002','00000000-0000-0000-0000-000000000001');
    SELECT count(*) INTO cnt FROM governance.transition_event
    WHERE entity_type='CHANGE_REQUEST'
      AND entity_id=(SELECT change_request_id FROM governance.change_request WHERE request_key='M10-CR-001')
      AND canonical_identity='M10-SEQ-002';
    INSERT INTO m10_results VALUES('M10-N02',CASE WHEN ev1=ev2 AND cnt=1 THEN 'PASS' ELSE 'BLOCKED' END,
      'Replay event identity preserved; event_count='||cnt);
  EXCEPTION WHEN OTHERS THEN
    INSERT INTO m10_results VALUES('M10-N02','BLOCKED','Replay failed: '||SQLERRM);
  END;
END $$;

-- M10-N03: failed transition must not create an additional event or mutate status.
DO $$
DECLARE s text; cnt integer;
BEGIN
  SELECT status INTO s FROM governance.change_request WHERE request_key='M10-CR-001';
  SELECT count(*) INTO cnt FROM governance.transition_event WHERE canonical_identity='M10-SEQ-N03';
  BEGIN
    PERFORM governance.transition_change_request(
      'M10-CR-001','CANDIDATE','APPLIED','1','M10_HASH_V1',
      'M10-SEQ-N03','00000000-0000-0000-0000-000000000001');
    INSERT INTO m10_results VALUES('M10-N03','BLOCKED','Invalid transition was accepted');
  EXCEPTION WHEN OTHERS THEN
    IF (SELECT status FROM governance.change_request WHERE request_key='M10-CR-001')=s
       AND (SELECT count(*) FROM governance.transition_event WHERE canonical_identity='M10-SEQ-N03')=cnt
    THEN
      INSERT INTO m10_results VALUES('M10-N03','PASS','Rejected transition left state and event evidence unchanged');
    ELSE
      INSERT INTO m10_results VALUES('M10-N03','BLOCKED','Rejected transition changed state or event evidence');
    END IF;
  END;
END $$;

-- M10-N04: event evidence must remain append-only.
DO $$
DECLARE ev uuid;
BEGIN
  SELECT transition_event_id INTO ev FROM governance.transition_event WHERE canonical_identity='M10-SEQ-001' LIMIT 1;
  BEGIN
    UPDATE governance.transition_event SET to_status='APPROVED' WHERE transition_event_id=ev;
    INSERT INTO m10_results VALUES('M10-N04','BLOCKED','Direct event UPDATE was allowed');
  EXCEPTION WHEN OTHERS THEN
    INSERT INTO m10_results VALUES('M10-N04','PASS','Direct event UPDATE rejected');
  END;
END $$;

-- M10-N05: explicit per-entity sequencing is required; created_at alone is not a deterministic sequence key.
DO $$
BEGIN
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='governance' AND table_name='transition_event'
      AND column_name IN ('sequence_no','event_sequence','event_number','ordinal')
  ) THEN
    INSERT INTO m10_results VALUES('M10-N05','PASS','Explicit event sequence column exists');
  ELSE
    INSERT INTO m10_results VALUES('M10-N05','BLOCKED','No explicit per-entity event sequence column; created_at alone is insufficient for deterministic ordering');
  END IF;
END $$;

SELECT test_id,result,detail FROM m10_results ORDER BY test_id;

DO $$
DECLARE blocked integer;
BEGIN
  SELECT count(*) INTO blocked FROM m10_results WHERE result='BLOCKED';
  IF blocked=0 THEN
    RAISE NOTICE 'M10 OVERALL: PASS';
  ELSE
    RAISE EXCEPTION 'M10 OVERALL: BLOCKED (% blocking findings)',blocked;
  END IF;
END $$;

ROLLBACK;
