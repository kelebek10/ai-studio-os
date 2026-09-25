BEGIN;

CREATE OR REPLACE FUNCTION m19_control.renew_lease(
    p_task uuid,
    p_executor text,
    p_seconds integer
)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = m19_control, public
AS $$
BEGIN
    IF p_seconds <= 0 OR p_seconds > 3600 THEN
        RAISE EXCEPTION 'invalid_lease_extension';
    END IF;

    IF NOT EXISTS (
        SELECT 1
        FROM m19_control.task_lease
        WHERE task_id = p_task
          AND executor_id = p_executor
          AND status = 'ACTIVE'
          AND expires_at > now()
    ) THEN
        RAISE EXCEPTION 'invalid_lease';
    END IF;

    UPDATE m19_control.task_lease
       SET expires_at = GREATEST(expires_at, now())
                         + (p_seconds || ' seconds')::interval,
           heartbeat_at = now()
     WHERE task_id = p_task
       AND executor_id = p_executor
       AND status = 'ACTIVE';

    RETURN true;
END
$$;

REVOKE ALL ON FUNCTION m19_control.renew_lease(uuid, text, integer) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION m19_control.renew_lease(uuid, text, integer) TO m19_app;

COMMIT;
