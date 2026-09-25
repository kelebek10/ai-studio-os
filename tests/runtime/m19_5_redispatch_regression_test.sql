-- M19.5 T6/T9 non-production regression and re-dispatch test
BEGIN;

DO $$
DECLARE
  v_task uuid := gen_random_uuid();
  v_corr uuid := gen_random_uuid();
  v_attempt1 uuid := gen_random_uuid();
  v_attempt2 uuid;
  v_assignment1 uuid;
  v_assignment2 uuid;
  v_lease uuid;
BEGIN
  INSERT INTO m19_control.task(task_id,correlation_id,task_type,agent_id,scope,source_commit,status)
  VALUES(v_task,v_corr,'M19.5_REDISPATCH_TEST','test-executor','nonprod','m19.5-t6','ACKNOWLEDGED');

  INSERT INTO m19_control.task_attempt(attempt_id,task_id,attempt_no,executor_id,source_commit,started_at,status)
  VALUES(v_attempt1,v_task,1,'executor-A','m19.5-t6',now(),'ACKNOWLEDGED');

  INSERT INTO m19_control.task_assignment(assignment_id,task_id,executor_id,scope,capability,registry_status,status,idempotency_key)
  VALUES(gen_random_uuid(),v_task,'executor-A','nonprod','test','ELIGIBLE','ACKNOWLEDGED','old-assignment');

  INSERT INTO m19_control.task_lease(lease_id,task_id,attempt_id,executor_id,issued_at,expires_at,status)
  VALUES(gen_random_uuid(),v_task,v_attempt1,'executor-A',now()-interval '2 minutes',now()-interval '1 minute','ACTIVE');

  v_attempt2 := m19_control.recover_expired_lease(v_task,'t6-recovery','executor-B','m19.5-t6');

  v_assignment1 := m19_control.dispatch_task(v_task,'executor-B','nonprod','test','ELIGIBLE','t6-recovery');
  v_assignment2 := m19_control.dispatch_task(v_task,'executor-B','nonprod','test','ELIGIBLE','t6-recovery');

  IF v_assignment1 IS DISTINCT FROM v_assignment2 THEN
    RAISE EXCEPTION 'T6_IDEMPOTENT_REDISPATCH_FAIL';
  END IF;

  PERFORM m19_control.ack_task(v_task,'executor-B');
  v_lease := m19_control.create_lease(v_task,v_attempt2,'executor-B',60);

  IF NOT EXISTS(
    SELECT 1 FROM m19_control.task_assignment
    WHERE assignment_id=v_assignment1 AND status='ACKNOWLEDGED'
      AND idempotency_key='t6-recovery'
  ) THEN RAISE EXCEPTION 'T6_ASSIGNMENT_FAIL'; END IF;

  IF NOT EXISTS(
    SELECT 1 FROM m19_control.task_lease
    WHERE lease_id=v_lease AND attempt_id=v_attempt2 AND executor_id='executor-B' AND status='ACTIVE'
  ) THEN RAISE EXCEPTION 'T6_LEASE_FAIL'; END IF;

  RAISE NOTICE 'M19.5 T_REDISPATCH PASS task=% attempt=% assignment=% lease=%',
    v_task,v_attempt2,v_assignment1,v_lease;
END $$;

ROLLBACK;

DO $$
DECLARE v_ok boolean := true;
BEGIN
  IF to_regclass('m19_control.task') IS NULL
     OR to_regclass('m19_control.task_attempt') IS NULL
     OR to_regclass('m19_control.task_assignment') IS NULL
     OR to_regclass('m19_control.task_lease') IS NULL
     OR to_regclass('m19_control.task_recovery') IS NULL
     OR to_regclass('m19_control.task_event') IS NULL THEN
    v_ok := false;
  END IF;

  IF NOT has_function_privilege('m19_app','m19_control.dispatch_task(uuid,text,text,text,text,text)','EXECUTE')
     OR NOT has_function_privilege('m19_app','m19_control.ack_task(uuid,text)','EXECUTE')
     OR NOT has_function_privilege('m19_app','m19_control.create_lease(uuid,uuid,text,integer)','EXECUTE')
     OR NOT has_function_privilege('m19_app','m19_control.renew_lease(uuid,text,integer)','EXECUTE')
     OR NOT has_function_privilege('m19_app','m19_control.recover_expired_lease(uuid,text,text,text)','EXECUTE') THEN
    v_ok := false;
  END IF;

  IF NOT v_ok THEN RAISE EXCEPTION 'T9_REGRESSION_FAIL'; END IF;
  RAISE NOTICE 'M19.5 T_REGRESSION PASS M19.3/M19.4/M19.5 controls present and executable by m19_app';
END $$;
