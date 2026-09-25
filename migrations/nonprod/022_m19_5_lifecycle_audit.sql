-- M19.5 non-production lifecycle audit hardening
BEGIN;

CREATE OR REPLACE FUNCTION m19_control.append_task_event(
  p_task uuid,
  p_event_type text,
  p_actor_type text,
  p_actor_id text,
  p_source_commit text,
  p_scope text,
  p_payload jsonb,
  p_idempotency_key text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path=m19_control,public
AS $$
DECLARE
  v_event_id uuid;
  v_corr uuid;
  v_seq bigint;
  v_existing uuid;
BEGIN
  SELECT event_id INTO v_existing
    FROM task_event
   WHERE task_id=p_task
     AND event_type=p_event_type
     AND idempotency_key=p_idempotency_key;
  IF FOUND THEN RETURN v_existing; END IF;

  SELECT correlation_id INTO v_corr FROM task WHERE task_id=p_task FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'task_not_found'; END IF;

  SELECT COALESCE(MAX(sequence_no),0)+1 INTO v_seq
    FROM task_event WHERE task_id=p_task;

  v_event_id := gen_random_uuid();

  INSERT INTO task_event(
    event_id,task_id,correlation_id,sequence_no,event_type,actor_type,actor_id,
    source_commit,scope,payload,payload_digest,idempotency_key
  ) VALUES (
    v_event_id,p_task,v_corr,v_seq,p_event_type,p_actor_type,p_actor_id,
    p_source_commit,p_scope,COALESCE(p_payload,'{}'::jsonb),
    md5(COALESCE(p_payload,'{}'::jsonb)::text),p_idempotency_key
  );

  UPDATE task SET current_sequence=v_seq,updated_at=now() WHERE task_id=p_task;
  RETURN v_event_id;
END $$;

CREATE OR REPLACE FUNCTION m19_control.dispatch_task(
  p_task uuid,p_executor text,p_scope text,p_capability text,
  p_registry_status text,p_key text
)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=m19_control,public AS $$
DECLARE v_id uuid; v_scope text;
BEGIN
 SELECT assignment_id INTO v_id FROM task_assignment
  WHERE task_id=p_task AND idempotency_key=p_key;
 IF FOUND THEN
   PERFORM append_task_event(p_task,'TASK_REDISPATCH_IDEMPOTENT','SYSTEM',p_executor,'m19.5','nonprod',
     jsonb_build_object('assignment_id',v_id,'idempotency_key',p_key),'dispatch-idempotent:'||p_key);
   RETURN v_id;
 END IF;

 SELECT scope INTO v_scope FROM task WHERE task_id=p_task FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'task_not_found'; END IF;
 IF p_scope IS DISTINCT FROM v_scope THEN RAISE EXCEPTION 'scope_mismatch'; END IF;
 IF p_registry_status <> 'ELIGIBLE' THEN RAISE EXCEPTION 'executor_not_eligible'; END IF;
 IF EXISTS(SELECT 1 FROM task_assignment WHERE task_id=p_task AND status='ACTIVE') THEN
   RAISE EXCEPTION 'active_assignment_exists';
 END IF;

 INSERT INTO task_assignment(assignment_id,task_id,executor_id,scope,capability,registry_status,status,idempotency_key)
 VALUES(gen_random_uuid(),p_task,p_executor,p_scope,p_capability,p_registry_status,'ACTIVE',p_key)
 RETURNING assignment_id INTO v_id;

 UPDATE task SET status='ASSIGNED',updated_at=now() WHERE task_id=p_task;
 PERFORM append_task_event(p_task,'TASK_DISPATCHED','SYSTEM',p_executor,'m19.5',p_scope,
   jsonb_build_object('assignment_id',v_id,'executor_id',p_executor,'idempotency_key',p_key),'dispatch:'||p_key);
 RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION m19_control.ack_task(p_task uuid,p_executor text)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=m19_control,public AS $$
BEGIN
 IF NOT EXISTS(SELECT 1 FROM task_assignment WHERE task_id=p_task AND executor_id=p_executor AND status='ACTIVE')
 THEN RAISE EXCEPTION 'invalid_ack'; END IF;
 UPDATE task_assignment SET status='ACKNOWLEDGED' WHERE task_id=p_task AND status='ACTIVE';
 UPDATE task SET status='ACKNOWLEDGED',updated_at=now() WHERE task_id=p_task;
 PERFORM append_task_event(p_task,'TASK_ACKNOWLEDGED','SYSTEM',p_executor,'m19.5','nonprod','{}'::jsonb,'ack:'||p_executor);
 RETURN true;
END $$;

CREATE OR REPLACE FUNCTION m19_control.create_lease(p_task uuid,p_attempt uuid,p_executor text,p_seconds integer)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=m19_control,public AS $$
DECLARE v_id uuid;
BEGIN
 IF NOT EXISTS(SELECT 1 FROM task_assignment WHERE task_id=p_task AND executor_id=p_executor AND status='ACKNOWLEDGED')
 THEN RAISE EXCEPTION 'assignment_not_acknowledged'; END IF;
 IF EXISTS(SELECT 1 FROM task_lease WHERE task_id=p_task AND status='ACTIVE') THEN RAISE EXCEPTION 'active_lease_exists'; END IF;
 INSERT INTO task_lease(lease_id,task_id,attempt_id,executor_id,expires_at,status)
 VALUES(gen_random_uuid(),p_task,p_attempt,p_executor,now()+(p_seconds||' seconds')::interval,'ACTIVE')
 RETURNING lease_id INTO v_id;
 PERFORM append_task_event(p_task,'LEASE_CREATED','SYSTEM',p_executor,'m19.5','nonprod',
   jsonb_build_object('lease_id',v_id,'attempt_id',p_attempt,'expires_in_seconds',p_seconds),'lease:'||v_id::text);
 RETURN v_id;
END $$;

CREATE OR REPLACE FUNCTION m19_control.renew_lease(p_task uuid,p_executor text,p_seconds integer)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=m19_control,public AS $$
DECLARE v_lease_id uuid;
BEGIN
 IF p_seconds <= 0 OR p_seconds > 3600 THEN RAISE EXCEPTION 'invalid_heartbeat_seconds'; END IF;
 UPDATE task_lease
    SET expires_at=GREATEST(expires_at,now())+(p_seconds||' seconds')::interval,
        heartbeat_at=now()
  WHERE task_id=p_task AND executor_id=p_executor AND status='ACTIVE' AND expires_at>now()
  RETURNING lease_id INTO v_lease_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'invalid_heartbeat'; END IF;
 PERFORM append_task_event(p_task,'LEASE_HEARTBEAT','SYSTEM',p_executor,'m19.5','nonprod',
   jsonb_build_object('lease_id',v_lease_id,'seconds',p_seconds),'heartbeat:'||v_lease_id::text||':'||extract(epoch from clock_timestamp())::bigint);
 RETURN true;
END $$;

CREATE OR REPLACE FUNCTION m19_control.recover_expired_lease(
 p_task uuid,p_recovery_key text,p_executor text,p_source_commit text)
RETURNS uuid LANGUAGE plpgsql SECURITY DEFINER SET search_path=m19_control,public AS $$
DECLARE v_lease task_lease%ROWTYPE; v_attempt_no integer; v_attempt_id uuid; v_existing uuid;
BEGIN
 SELECT recovered_attempt_id INTO v_existing FROM task_recovery
 WHERE task_id=p_task AND recovery_key=p_recovery_key;
 IF FOUND THEN
   PERFORM append_task_event(p_task,'RECOVERY_IDEMPOTENT','SYSTEM',p_executor,p_source_commit,'nonprod',
     jsonb_build_object('recovery_key',p_recovery_key,'attempt_id',v_existing),'recovery-idempotent:'||p_recovery_key);
   RETURN v_existing;
 END IF;

 SELECT * INTO v_lease FROM task_lease WHERE task_id=p_task AND status='ACTIVE' FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'no_active_lease'; END IF;
 IF v_lease.expires_at>now() THEN RAISE EXCEPTION 'lease_not_expired'; END IF;

 UPDATE task_lease SET status='EXPIRED' WHERE lease_id=v_lease.lease_id AND status='ACTIVE';
 UPDATE task_assignment SET status='RECOVERED' WHERE task_id=p_task AND status='ACKNOWLEDGED';

 SELECT COALESCE(MAX(attempt_no),0)+1 INTO v_attempt_no FROM task_attempt WHERE task_id=p_task;
 v_attempt_id:=gen_random_uuid();
 INSERT INTO task_attempt(attempt_id,task_id,attempt_no,executor_id,source_commit,started_at,status)
 VALUES(v_attempt_id,p_task,v_attempt_no,p_executor,p_source_commit,now(),'CREATED');

 INSERT INTO task_recovery(recovery_id,task_id,source_lease_id,source_attempt_id,recovery_key,recovered_attempt_id)
 VALUES(gen_random_uuid(),p_task,v_lease.lease_id,v_lease.attempt_id,p_recovery_key,v_attempt_id);

 PERFORM append_task_event(p_task,'LEASE_RECOVERED','SYSTEM',p_executor,p_source_commit,'nonprod',
   jsonb_build_object('source_lease_id',v_lease.lease_id,'source_attempt_id',v_lease.attempt_id,
                      'recovered_attempt_id',v_attempt_id,'recovery_key',p_recovery_key),
   'recovery:'||p_recovery_key);
 RETURN v_attempt_id;
END $$;

REVOKE ALL ON FUNCTION m19_control.append_task_event(uuid,text,text,text,text,text,jsonb,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION m19_control.append_task_event(uuid,text,text,text,text,text,jsonb,text) TO m19_app;

REVOKE ALL ON FUNCTION m19_control.dispatch_task(uuid,text,text,text,text,text),m19_control.ack_task(uuid,text),m19_control.create_lease(uuid,uuid,text,integer),m19_control.renew_lease(uuid,text,integer),m19_control.recover_expired_lease(uuid,text,text,text) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION m19_control.dispatch_task(uuid,text,text,text,text,text),m19_control.ack_task(uuid,text),m19_control.create_lease(uuid,uuid,text,integer),m19_control.renew_lease(uuid,text,integer),m19_control.recover_expired_lease(uuid,text,text,text) TO m19_app;

COMMIT;
