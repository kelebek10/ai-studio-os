-- M20.2 controlled smoke: L0-L2 control-plane + recovery
-- NONPROD ONLY. Transaction rolls back all fixture state.
BEGIN;
DO $$
DECLARE
  v_task uuid:=gen_random_uuid(); v_corr uuid:=gen_random_uuid();
  v_attempt uuid:=gen_random_uuid(); v_attempt2 uuid;
  v_assign uuid; v_lease uuid; v_lease2 uuid;
  v_events int; v_active int;
BEGIN
  INSERT INTO m19_control.task(task_id,correlation_id,task_type,agent_id,scope,source_commit,status)
  VALUES(v_task,v_corr,'M20.2_SMOKE','smoke-agent','nonprod','m20.2-smoke','CREATED');

  INSERT INTO m19_control.task_attempt(attempt_id,task_id,attempt_no,executor_id,source_commit,started_at,status)
  VALUES(v_attempt,v_task,1,'smoke-executor-A','m20.2-smoke',now(),'ACKNOWLEDGED');

  v_assign:=m19_control.dispatch_task(v_task,'smoke-executor-A','nonprod','smoke','ELIGIBLE','m20.2-dispatch-1');
  PERFORM m19_control.ack_task(v_task,'smoke-executor-A');
  v_lease:=m19_control.create_lease(v_task,v_attempt,'smoke-executor-A',60);
  PERFORM m19_control.renew_lease(v_task,'smoke-executor-A',60);

  UPDATE m19_control.task_lease SET expires_at=now()-interval '1 second'
    WHERE lease_id=v_lease;

  v_attempt2:=m19_control.recover_expired_lease(v_task,'m20.2-recovery-1','smoke-executor-B','m20.2-smoke');

  v_assign:=m19_control.dispatch_task(v_task,'smoke-executor-B','nonprod','smoke','ELIGIBLE','m20.2-dispatch-2');
  PERFORM m19_control.ack_task(v_task,'smoke-executor-B');
  v_lease2:=m19_control.create_lease(v_task,v_attempt2,'smoke-executor-B',60);

  SELECT count(*) INTO v_events FROM m19_control.task_event WHERE task_id=v_task;
  SELECT count(*) INTO v_active FROM m19_control.task_lease WHERE task_id=v_task AND status='ACTIVE';

  IF v_attempt2 IS NULL THEN RAISE EXCEPTION 'RECOVERY_ATTEMPT_MISSING'; END IF;
  IF v_events < 8 THEN RAISE EXCEPTION 'AUDIT_EVENT_COUNT_FAIL got=%',v_events; END IF;
  IF v_active <> 1 THEN RAISE EXCEPTION 'ACTIVE_LEASE_COUNT_FAIL got=%',v_active; END IF;
  IF (SELECT count(*) FROM m19_control.task_event WHERE task_id=v_task AND correlation_id=v_corr) <> v_events
    THEN RAISE EXCEPTION 'CORRELATION_LINEAGE_FAIL'; END IF;

  RAISE NOTICE 'M20.2 L0-L2 CONTROL SMOKE PASS task=% events=% attempt2=% active_leases=%',
    v_task,v_events,v_attempt2,v_active;
END $$;
ROLLBACK;
