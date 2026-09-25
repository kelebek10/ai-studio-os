-- M19.5 T7 lifecycle audit evidence: verify event ledger supports ordered, linked lifecycle records
BEGIN;
DO $$
DECLARE
  v_task uuid := gen_random_uuid();
  v_corr uuid := gen_random_uuid();
  v_e1 uuid := gen_random_uuid();
  v_e2 uuid := gen_random_uuid();
  v_e3 uuid := gen_random_uuid();
  v_count integer;
BEGIN
  INSERT INTO m19_control.task(task_id,correlation_id,task_type,agent_id,scope,source_commit,status)
  VALUES(v_task,v_corr,'M19.5_AUDIT_TEST','audit-executor','nonprod','m19.5-t7','CREATED');

  INSERT INTO m19_control.task_event(
    event_id,task_id,correlation_id,sequence_no,event_type,actor_type,actor_id,
    source_commit,scope,payload,payload_digest,idempotency_key
  ) VALUES
    (v_e1,v_task,v_corr,1,'TASK_CREATED','SYSTEM','m19.5-test','m19.5-t7','nonprod','{}','digest-1','audit-1'),
    (v_e2,v_task,v_corr,2,'LEASE_EXPIRED','SYSTEM','m19.5-test','m19.5-t7','nonprod','{}','digest-2','audit-2'),
    (v_e3,v_task,v_corr,3,'RECOVERY_CREATED','SYSTEM','m19.5-test','m19.5-t7','nonprod','{}','digest-3','audit-3');

  SELECT count(*) INTO v_count
    FROM m19_control.task_event
   WHERE task_id=v_task
     AND correlation_id=v_corr
     AND sequence_no IN (1,2,3);

  IF v_count <> 3 THEN RAISE EXCEPTION 'T7_EVENT_COUNT_FAIL'; END IF;

  IF EXISTS (
    SELECT 1 FROM (
      SELECT sequence_no, lag(sequence_no) OVER (ORDER BY sequence_no) prev
      FROM m19_control.task_event WHERE task_id=v_task
    ) q WHERE prev IS NOT NULL AND sequence_no <> prev+1
  ) THEN RAISE EXCEPTION 'T7_SEQUENCE_FAIL'; END IF;

  IF (SELECT count(*) FROM m19_control.task_event
      WHERE task_id=v_task AND correlation_id=v_corr
        AND causation_id IS NULL) <> 3 THEN
    RAISE EXCEPTION 'T7_CAUSATION_EXPECTATION_FAIL';
  END IF;

  RAISE NOTICE 'M19.5 T_AUDIT_LEDGER PASS task=% events=3 ordered=%',v_task,true;
END $$;
ROLLBACK;
