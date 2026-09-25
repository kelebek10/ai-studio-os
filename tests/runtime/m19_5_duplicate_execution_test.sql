BEGIN;

DO $$
DECLARE
    v_task uuid := gen_random_uuid();
    v_attempt_a uuid := gen_random_uuid();
    v_attempt_b uuid := gen_random_uuid();
    v_lease_a uuid := gen_random_uuid();
    v_failed boolean := false;
    v_active integer;
BEGIN
    INSERT INTO m19_control.task(
        task_id,correlation_id,task_type,agent_id,scope,source_commit,status
    ) VALUES (
        v_task,gen_random_uuid(),'M19.5_DUPLICATE_TEST','test-executor','nonprod','m19.5-test','ACKNOWLEDGED'
    );

    INSERT INTO m19_control.task_attempt(
        attempt_id,task_id,attempt_no,executor_id,source_commit,started_at,status
    ) VALUES
        (v_attempt_a,v_task,1,'executor-A','m19.5-test',now(),'ACKNOWLEDGED'),
        (v_attempt_b,v_task,2,'executor-B','m19.5-test',now(),'CREATED');

    INSERT INTO m19_control.task_lease(
        lease_id,task_id,attempt_id,executor_id,issued_at,expires_at,status
    ) VALUES (
        v_lease_a,v_task,v_attempt_a,'executor-A',now(),now()+interval '60 seconds','ACTIVE'
    );

    BEGIN
        INSERT INTO m19_control.task_lease(
            lease_id,task_id,attempt_id,executor_id,issued_at,expires_at,status
        ) VALUES (
            gen_random_uuid(),v_task,v_attempt_b,'executor-B',now(),now()+interval '60 seconds','ACTIVE'
        );
    EXCEPTION WHEN unique_violation THEN
        v_failed := true;
    END;

    IF NOT v_failed THEN
        RAISE EXCEPTION 'T_DUPLICATE_ACTIVE_LEASE_REJECTION_FAIL';
    END IF;

    SELECT count(*) INTO v_active
      FROM m19_control.task_lease
     WHERE task_id=v_task AND status='ACTIVE';

    IF v_active <> 1 THEN
        RAISE EXCEPTION 'T_SINGLE_ACTIVE_LEASE_FAIL';
    END IF;

    RAISE NOTICE 'M19.5 T_DUPLICATE_EXECUTION PASS task=%',v_task;
END
$$;

ROLLBACK;
