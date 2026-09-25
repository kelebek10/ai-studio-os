BEGIN;

CREATE TABLE IF NOT EXISTS m19_control.task_recovery (
    recovery_id uuid PRIMARY KEY,
    task_id uuid NOT NULL REFERENCES m19_control.task(task_id) ON DELETE RESTRICT,
    source_lease_id uuid NOT NULL REFERENCES m19_control.task_lease(lease_id) ON DELETE RESTRICT,
    source_attempt_id uuid NOT NULL REFERENCES m19_control.task_attempt(attempt_id) ON DELETE RESTRICT,
    recovery_key text NOT NULL,
    recovered_attempt_id uuid NOT NULL REFERENCES m19_control.task_attempt(attempt_id) ON DELETE RESTRICT,
    created_at timestamptz NOT NULL DEFAULT now(),
    UNIQUE(task_id,recovery_key),
    UNIQUE(source_lease_id)
);

CREATE OR REPLACE FUNCTION m19_control.recover_expired_lease(
    p_task uuid,
    p_recovery_key text,
    p_executor text,
    p_source_commit text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = m19_control, public
AS $$
DECLARE
    v_lease task_lease%ROWTYPE;
    v_attempt_no integer;
    v_attempt_id uuid;
    v_existing uuid;
BEGIN
    SELECT recovered_attempt_id INTO v_existing
      FROM task_recovery
     WHERE task_id = p_task AND recovery_key = p_recovery_key;
    IF FOUND THEN
        RETURN v_existing;
    END IF;

    SELECT * INTO v_lease
      FROM task_lease
     WHERE task_id = p_task
       AND status = 'ACTIVE'
     FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'no_active_lease';
    END IF;

    IF v_lease.expires_at > now() THEN
        RAISE EXCEPTION 'lease_not_expired';
    END IF;

    UPDATE task_lease
       SET status = 'EXPIRED'
     WHERE lease_id = v_lease.lease_id
       AND status = 'ACTIVE';

    UPDATE task_assignment
       SET status = 'RECOVERED'
     WHERE task_id = p_task
       AND status = 'ACKNOWLEDGED';

    SELECT COALESCE(MAX(attempt_no),0) + 1
      INTO v_attempt_no
      FROM task_attempt
     WHERE task_id = p_task;

    v_attempt_id := gen_random_uuid();

    INSERT INTO task_attempt(
        attempt_id,task_id,attempt_no,executor_id,source_commit,started_at,status
    )
    VALUES(
        v_attempt_id,p_task,v_attempt_no,p_executor,p_source_commit,now(),'CREATED'
    );

    INSERT INTO task_recovery(
        recovery_id,task_id,source_lease_id,source_attempt_id,
        recovery_key,recovered_attempt_id
    )
    VALUES(
        gen_random_uuid(),p_task,v_lease.lease_id,v_lease.attempt_id,
        p_recovery_key,v_attempt_id
    );

    RETURN v_attempt_id;
END
$$;

REVOKE ALL ON FUNCTION m19_control.recover_expired_lease(uuid,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION m19_control.recover_expired_lease(uuid,text,text,text) TO m19_app;

COMMIT;
