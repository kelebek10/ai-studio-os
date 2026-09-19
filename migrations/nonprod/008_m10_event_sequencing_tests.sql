-- PAI-FORGE M10 Event Sequencing tests v1.1
-- Disposable PostgreSQL only. Never production.
-- Requires 009_m10_event_sequencing_enforcement.sql.

\set ON_ERROR_STOP on
BEGIN;

DO $$
BEGIN
  IF current_database() <> 'paiforge_test' THEN RAISE EXCEPTION 'M10_TEST_GUARD: expected paiforge_test, got %',current_database(); END IF;
END $$;

CREATE TEMP TABLE m10_results(test_id text PRIMARY KEY,result text NOT NULL,detail text NOT NULL);

DO $$
BEGIN
  IF to_regclass('governance.transition_event') IS NULL THEN INSERT INTO m10_results VALUES('M10-00','BLOCKED','transition_event missing');
  ELSIF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_schema='governance' AND table_name='transition_event' AND column_name='event_sequence') THEN INSERT INTO m10_results VALUES('M10-00','BLOCKED','event_sequence missing');
  ELSE INSERT INTO m10_results VALUES('M10-00','PASS','event boundary and sequence column exist'); END IF;
END $$;

INSERT INTO governance.design_state(design_id,state_version,state_hash,ruleset_version,created_by)
VALUES('00000000-0000-0000-0000-000000001010',1,'M10_HASH_V1','M10-R1','00000000-0000-0000-0000-000000000001');
INSERT INTO governance.change_request(request_key,design_state_id,expected_state_version,canonical_request_hash,status,created_by)
SELECT 'M10-CR-001',design_state_id,1,'M10-CR-HASH','CANDIDATE','00000000-0000-0000-0000-000000000001' FROM governance.design_state WHERE design_id='00000000-0000-0000-0000-000000001010';

DO $$
DECLARE ev uuid; seq bigint; cnt integer;
BEGIN
 BEGIN
  ev:=governance.transition_change_request('M10-CR-001','CANDIDATE','VERIFIED','1','M10_HASH_V1','M10-SEQ-001','00000000-0000-0000-0000-000000000001');
  SELECT event_sequence INTO seq FROM governance.transition_event WHERE transition_event_id=ev;
  SELECT count(*) INTO cnt FROM governance.transition_event WHERE entity_type='CHANGE_REQUEST' AND entity_id=(SELECT change_request_id FROM governance.change_request WHERE request_key='M10-CR-001');
  INSERT INTO m10_results VALUES('M10-P01',CASE WHEN cnt=1 AND seq=1 THEN 'PASS' ELSE 'BLOCKED' END,'First controlled event sequence='||coalesce(seq::text,'NULL')||'; count='||cnt);
 EXCEPTION WHEN OTHERS THEN INSERT INTO m10_results VALUES('M10-P01','BLOCKED','Controlled transition failed: '||SQLERRM); END;
END $$;

DO $$
BEGIN
 BEGIN
  PERFORM governance.transition_change_request('M10-CR-001','CANDIDATE','APPROVED','1','M10_HASH_V1','M10-SEQ-N01','00000000-0000-0000-0000-000000000001');
  INSERT INTO m10_results VALUES('M10-N01','BLOCKED','Invalid predecessor/order accepted');
 EXCEPTION WHEN OTHERS THEN INSERT INTO m10_results VALUES('M10-N01','PASS','Invalid predecessor/order rejected: '||SQLERRM); END;
END $$;

DO $$
DECLARE ev1 uuid; ev2 uuid; seq2 bigint; cnt integer;
BEGIN
 BEGIN
  ev1:=governance.transition_change_request('M10-CR-001','VERIFIED','APPROVED','1','M10_HASH_V1','M10-SEQ-002','00000000-0000-0000-0000-000000000001');
  ev2:=governance.transition_change_request('M10-CR-001','VERIFIED','APPROVED','1','M10_HASH_V1','M10-SEQ-002','00000000-0000-0000-0000-000000000001');
  SELECT event_sequence INTO seq2 FROM governance.transition_event WHERE transition_event_id=ev2;
  SELECT count(*) INTO cnt FROM governance.transition_event WHERE entity_type='CHANGE_REQUEST' AND entity_id=(SELECT change_request_id FROM governance.change_request WHERE request_key='M10-CR-001');
  INSERT INTO m10_results VALUES('M10-N02',CASE WHEN ev1=ev2 AND seq2=2 AND cnt=2 THEN 'PASS' ELSE 'BLOCKED' END,'Replay preserved event identity; second sequence='||coalesce(seq2::text,'NULL')||'; total='||cnt);
 EXCEPTION WHEN OTHERS THEN INSERT INTO m10_results VALUES('M10-N02','BLOCKED','Replay failed: '||SQLERRM); END;
END $$;

DO $$
DECLARE s text; before_cnt integer; after_cnt integer;
BEGIN
 SELECT status INTO s FROM governance.change_request WHERE request_key='M10-CR-001';
 SELECT count(*) INTO before_cnt FROM governance.transition_event WHERE entity_id=(SELECT change_request_id FROM governance.change_request WHERE request_key='M10-CR-001');
 BEGIN
  PERFORM governance.transition_change_request('M10-CR-001','CANDIDATE','APPLIED','1','M10_HASH_V1','M10-SEQ-N03','00000000-0000-0000-0000-000000000001');
  INSERT INTO m10_results VALUES('M10-N03','BLOCKED','Invalid transition accepted');
 EXCEPTION WHEN OTHERS THEN
  SELECT count(*) INTO after_cnt FROM governance.transition_event WHERE entity_id=(SELECT change_request_id FROM governance.change_request WHERE request_key='M10-CR-001');
  IF (SELECT status FROM governance.change_request WHERE request_key='M10-CR-001')=s AND after_cnt=before_cnt THEN INSERT INTO m10_results VALUES('M10-N03','PASS','Rejected transition left state/event evidence unchanged'); ELSE INSERT INTO m10_results VALUES('M10-N03','BLOCKED','Rejected transition changed state/event evidence'); END IF;
 END;
END $$;

DO $$
DECLARE ev uuid;
BEGIN
 SELECT transition_event_id INTO ev FROM governance.transition_event WHERE canonical_identity='M10-SEQ-001' LIMIT 1;
 BEGIN UPDATE governance.transition_event SET to_status='APPROVED' WHERE transition_event_id=ev; INSERT INTO m10_results VALUES('M10-N04','BLOCKED','Direct event UPDATE was allowed'); EXCEPTION WHEN OTHERS THEN INSERT INTO m10_results VALUES('M10-N04','PASS','Direct event UPDATE rejected: '||SQLERRM); END;
END $$;

DO $$
DECLARE s1 bigint; s2 bigint; bad integer;
BEGIN
 SELECT min(event_sequence),max(event_sequence) INTO s1,s2 FROM governance.transition_event WHERE entity_type='CHANGE_REQUEST' AND entity_id=(SELECT change_request_id FROM governance.change_request WHERE request_key='M10-CR-001');
 SELECT count(*) INTO bad FROM governance.transition_event WHERE entity_type='CHANGE_REQUEST' AND entity_id=(SELECT change_request_id FROM governance.change_request WHERE request_key='M10-CR-001') AND event_sequence NOT IN (1,2);
 INSERT INTO m10_results VALUES('M10-N05',CASE WHEN s1=1 AND s2=2 AND bad=0 THEN 'PASS' ELSE 'BLOCKED' END,'Per-entity sequence is monotonic 1..2');
END $$;

SELECT test_id,result,detail FROM m10_results ORDER BY test_id;
DO $$ DECLARE blocked integer;
BEGIN SELECT count(*) INTO blocked FROM m10_results WHERE result='BLOCKED'; IF blocked=0 THEN RAISE NOTICE 'M10 OVERALL: PASS'; ELSE RAISE EXCEPTION 'M10 OVERALL: BLOCKED (% blocking findings)',blocked; END IF; END $$;
ROLLBACK;
