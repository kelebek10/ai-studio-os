-- M19.5 T7 full lifecycle audit evidence
BEGIN;
DO $$
DECLARE
 v_task uuid:=gen_random_uuid(); v_corr uuid:=gen_random_uuid();
 v_attempt1 uuid:=gen_random_uuid(); v_attempt2 uuid;
 v_assign uuid; v_lease uuid; v_lease2 uuid; v_count int;
BEGIN
 INSERT INTO m19_control.task(task_id,correlation_id,task_type,agent_id,scope,source_commit,status)
 VALUES(v_task,v_corr,'M19.5_FULL_AUDIT','audit','nonprod','m19.5-t7','CREATED');
 INSERT INTO m19_control.task_attempt(attempt_id,task_id,attempt_no,executor_id,source_commit,started_at,status)
 VALUES(v_attempt1,v_task,1,'executor-A','m19.5-t7',now(),'ACKNOWLEDGED');

 v_assign:=m19_control.dispatch_task(v_task,'executor-A','nonprod','audit','ELIGIBLE','audit-dispatch-1');
 PERFORM m19_control.ack_task(v_task,'executor-A');
 v_lease:=m19_control.create_lease(v_task,v_attempt1,'executor-A',60);
 PERFORM m19_control.renew_lease(v_task,'executor-A',60);

 UPDATE m19_control.task_lease SET expires_at=now()-interval '1 second' WHERE lease_id=v_lease;
 v_attempt2:=m19_control.recover_expired_lease(v_task,'audit-recovery-1','executor-B','m19.5-t7');

 v_assign:=m19_control.dispatch_task(v_task,'executor-B','nonprod','audit','ELIGIBLE','audit-dispatch-2');
 PERFORM m19_control.ack_task(v_task,'executor-B');
 v_lease2:=m19_control.create_lease(v_task,v_attempt2,'executor-B',60);

 SELECT count(*) INTO v_count FROM m19_control.task_event WHERE task_id=v_task;
 IF v_count < 7 THEN RAISE EXCEPTION 'T7_FULL_AUDIT_EVENT_COUNT_FAIL got=%',v_count; END IF;

 IF (SELECT count(*) FROM m19_control.task_event WHERE task_id=v_task AND correlation_id=v_corr) <> v_count
 THEN RAISE EXCEPTION 'T7_CORRELATION_FAIL'; END IF;

 IF EXISTS (
   SELECT 1 FROM (SELECT sequence_no,lag(sequence_no) OVER(ORDER BY sequence_no) p FROM m19_control.task_event WHERE task_id=v_task) q
   WHERE p IS NOT NULL AND sequence_no<>p+1
 ) THEN RAISE EXCEPTION 'T7_SEQUENCE_FAIL'; END IF;

 IF NOT EXISTS(SELECT 1 FROM m19_control.task_event WHERE task_id=v_task AND event_type='TASK_DISPATCHED') THEN RAISE EXCEPTION 'T7_DISPATCH_EVENT_FAIL'; END IF;
 IF NOT EXISTS(SELECT 1 FROM m19_control.task_event WHERE task_id=v_task AND event_type='TASK_ACKNOWLEDGED') THEN RAISE EXCEPTION 'T7_ACK_EVENT_FAIL'; END IF;
 IF NOT EXISTS(SELECT 1 FROM m19_control.task_event WHERE task_id=v_task AND event_type='LEASE_CREATED') THEN RAISE EXCEPTION 'T7_LEASE_EVENT_FAIL'; END IF;
 IF NOT EXISTS(SELECT 1 FROM m19_control.task_event WHERE task_id=v_task AND event_type='LEASE_HEARTBEAT') THEN RAISE EXCEPTION 'T7_HEARTBEAT_EVENT_FAIL'; END IF;
 IF NOT EXISTS(SELECT 1 FROM m19_control.task_event WHERE task_id=v_task AND event_type='LEASE_RECOVERED') THEN RAISE EXCEPTION 'T7_RECOVERY_EVENT_FAIL'; END IF;

 RAISE NOTICE 'M19.5 T_FULL_LIFECYCLE_AUDIT PASS task=% events=% attempt2=% lease2=%',v_task,v_count,v_attempt2,v_lease2;
END $$;
ROLLBACK;
