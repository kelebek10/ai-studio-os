-- M19.5 non-production fix: make dispatch idempotency deterministic before active-assignment guard
BEGIN;

CREATE OR REPLACE FUNCTION m19_control.dispatch_task(
  p_task uuid,p_executor text,p_scope text,p_capability text,
  p_registry_status text,p_key text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=m19_control,public
AS $$
DECLARE
  v_id uuid;
  v_scope text;
BEGIN
  SELECT assignment_id INTO v_id
    FROM task_assignment
   WHERE task_id=p_task AND idempotency_key=p_key;

  IF FOUND THEN
    RETURN v_id;
  END IF;

  SELECT scope INTO v_scope FROM task WHERE task_id=p_task FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'task_not_found'; END IF;
  IF p_scope IS DISTINCT FROM v_scope THEN RAISE EXCEPTION 'scope_mismatch'; END IF;
  IF p_registry_status <> 'ELIGIBLE' THEN RAISE EXCEPTION 'executor_not_eligible'; END IF;
  IF EXISTS(SELECT 1 FROM task_assignment WHERE task_id=p_task AND status='ACTIVE') THEN
    RAISE EXCEPTION 'active_assignment_exists';
  END IF;

  INSERT INTO task_assignment(
    assignment_id,task_id,executor_id,scope,capability,registry_status,status,idempotency_key
  )
  VALUES(
    gen_random_uuid(),p_task,p_executor,p_scope,p_capability,p_registry_status,'ACTIVE',p_key
  )
  ON CONFLICT (task_id,idempotency_key) DO NOTHING
  RETURNING assignment_id INTO v_id;

  IF v_id IS NULL THEN
    SELECT assignment_id INTO v_id
      FROM task_assignment
     WHERE task_id=p_task AND idempotency_key=p_key;
  END IF;

  UPDATE task SET status='ASSIGNED',updated_at=now() WHERE task_id=p_task;
  RETURN v_id;
END $$;

REVOKE ALL ON FUNCTION m19_control.dispatch_task(uuid,text,text,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION m19_control.dispatch_task(uuid,text,text,text,text,text) TO m19_app;

COMMIT;
