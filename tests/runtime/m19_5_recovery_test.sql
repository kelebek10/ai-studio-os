BEGIN;

DO $$
DECLARE
    v_task uuid := gen_random_uuid();
    v_corr uuid := gen_random_uuid();
    v_attempt uuid := gen_random_uuid();
    v_lease uuid := gen_random_uuid();
    v_recovered uuid;
    v_recovered_again uuid;
    v_source_attempt uuid;
    v_count integer;
BEGIN
    INSERT INTO m19_control.task(
        task_id,correlation_id,task_type,agent_id,scope,source_commit,status
    ) VALUES (
        v_task,v_corr,'M19.5_RECOVERY_TEST','test-executor','nonprod','m19.5-test','ACKNOWLEDGED'
    );

    INSERT INTO m19_control.task_attempt(
        attempt_id,task_id,attempt_no,executor_id,source_commit,started_at,status
    ) VALUES (
        v_attempt,v_task,1,'executor-A','m19.5-test',now() - interval '2 minutes','ACKNOWLEDGED'
    );

    INSERT INTO m19_control.task_assignment(
        assignment_id,task_id,executor_id,scope,capability,registry_status,status,idempotency_key
    ) VALUES (
        gen_random_uuid(),v_task,'executor-A','nonprod','test','ELIGIBLE','ACKNOWLEDGED','m19.5-test-assignment'
    );

    INSERT INTO m19_control.task_lease(
        lease_id,task_id,attempt_id,executor_id,issued_at,expires_at,status
    ) VALUES (
        v_lease,v_task,v_attempt,'executor-A',now()-interval '2 minutes',
        now()-interval '1 minute','ACTIVE'
    );

    v_recovered := m19_control.recover_expired_lease(
        v_task,'m19.5-recovery-key','executor-B','m19.5-test'
    );

    SELECT source_attempt_id INTO v_source_attempt
      FROM m19_control.task_recovery
     WHERE task_id=v_task AND recovery_key='m19.5-recovery-key';

    IF v_source_attempt <> v_attempt THEN
        RAISE EXCEPTION 'T_RECOVERY_LINEAGE_FAIL';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM m19_control.task_lease
        WHERE lease_id=v_lease AND status='EXPIRED'
    ) THEN
        RAISE EXCEPTION 'T_EXPIRED_LEASE_FAIL';
    END IF;

    IF NOT EXISTS (
        SELECT 1 FROM m19_control.task_attempt
        WHERE attempt_id=v_recovered AND task_id=v_task AND attempt_no=2
          AND executor_id='executor-B'
    ) THEN
        RAISE EXCEPTION 'T_NEW_ATTEMPT_FAIL';
    END IF;

    v_recovered_again := m19_control.recover_expired_lease(
        v_task,'m19.5-recovery-key','executor-C','different-commit'
    );

    IF v_recovered_again <> v_recovered THEN
        RAISE EXCEPTION 'T_IDEMPOTENCY_FAIL';
    END IF;

    SELECT count(*) INTO v_count
      FROM m19_control.task_recovery
     WHERE task_id=v_task AND recovery_key='m19.5-recovery-key';

    IF v_count <> 1 THEN
        RAISE EXCEPTION 'T_RECOVERY_DUPLICATE_FAIL';
    END IF;

    RAISE NOTICE 'M19.5 T_RECOVERY PASS task=% attempt=%',v_task,v_recovered;
END
$$;

ROLLBACK;
