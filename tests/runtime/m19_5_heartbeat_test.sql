BEGIN;

DO $$
DECLARE
    v_task uuid := gen_random_uuid();
    v_attempt uuid := gen_random_uuid();
    v_lease uuid := gen_random_uuid();
    v_before timestamptz;
    v_after timestamptz;
    v_failed boolean := false;
BEGIN
    INSERT INTO m19_control.task(
        task_id,correlation_id,task_type,agent_id,scope,source_commit,status
    ) VALUES (
        v_task,gen_random_uuid(),'M19.5_HEARTBEAT_TEST','test-executor','nonprod','m19.5-test','EXECUTING'
    );

    INSERT INTO m19_control.task_attempt(
        attempt_id,task_id,attempt_no,executor_id,source_commit,started_at,status
    ) VALUES (
        v_attempt,v_task,1,'executor-A','m19.5-test',now(),'ACKNOWLEDGED'
    );

    INSERT INTO m19_control.task_lease(
        lease_id,task_id,attempt_id,executor_id,issued_at,expires_at,heartbeat_at,status
    ) VALUES (
        v_lease,v_task,v_attempt,'executor-A',now(),now()+interval '30 seconds',now(),'ACTIVE'
    );

    SELECT expires_at INTO v_before FROM m19_control.task_lease WHERE lease_id=v_lease;

    PERFORM m19_control.renew_lease(v_task,'executor-A',60);

    SELECT expires_at INTO v_after FROM m19_control.task_lease WHERE lease_id=v_lease;

    IF v_after <= v_before THEN
        RAISE EXCEPTION 'T_HEARTBEAT_EXTENSION_FAIL';
    END IF;

    BEGIN
        PERFORM m19_control.renew_lease(v_task,'executor-B',60);
    EXCEPTION WHEN OTHERS THEN
        v_failed := true;
    END;

    IF NOT v_failed THEN
        RAISE EXCEPTION 'T_STALE_EXECUTOR_REJECTION_FAIL';
    END IF;

    RAISE NOTICE 'M19.5 T_HEARTBEAT PASS task=% lease=%',v_task,v_lease;
END
$$;

ROLLBACK;
