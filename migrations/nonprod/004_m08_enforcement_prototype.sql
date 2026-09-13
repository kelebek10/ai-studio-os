-- PAI-FORGE M08 ENFORCEMENT PROTOTYPE v1.0
-- Disposable PostgreSQL only. Apply AFTER 001_paiforge_v13_test.sql.
-- Production migration remains blocked.

BEGIN;

CREATE TABLE IF NOT EXISTS governance.transition_event (
  transition_event_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  entity_type text NOT NULL CHECK (entity_type IN ('CHANGE_REQUEST','ALTERNATIVE','CONFLICT','RESOLUTION')),
  entity_id uuid NOT NULL,
  from_status text NOT NULL,
  to_status text NOT NULL,
  expected_state_version bigint,
  expected_state_hash text,
  canonical_identity text NOT NULL,
  actor_id uuid NOT NULL,
  authorization_ref text,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(entity_type, canonical_identity)
);

CREATE INDEX IF NOT EXISTS ix_transition_event_entity ON governance.transition_event(entity_type,entity_id,created_at);

CREATE OR REPLACE FUNCTION governance.m08_transition_guard() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF current_setting('paiforge.transition_context',true) <> 'CONTROLLED' THEN
    RAISE EXCEPTION 'DIRECT_MUTATION_BLOCKED: use controlled transition function';
  END IF;
  RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS change_request_transition_guard ON governance.change_request;
CREATE TRIGGER change_request_transition_guard
BEFORE UPDATE ON governance.change_request
FOR EACH ROW EXECUTE FUNCTION governance.m08_transition_guard();

DROP TRIGGER IF EXISTS alternative_transition_guard ON governance.alternative;
CREATE TRIGGER alternative_transition_guard
BEFORE UPDATE ON governance.alternative
FOR EACH ROW EXECUTE FUNCTION governance.m08_transition_guard();

CREATE OR REPLACE FUNCTION governance.transition_change_request(
  p_request_key text,
  p_from_status text,
  p_to_status text,
  p_expected_state_version text,
  p_expected_state_hash text,
  p_canonical_identity text,
  p_actor_id text
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path=governance,core,public AS $$
DECLARE r governance.change_request%ROWTYPE; ds governance.design_state%ROWTYPE; ev uuid;
BEGIN
  SELECT * INTO r FROM governance.change_request WHERE request_key=p_request_key FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'CHANGE_REQUEST_NOT_FOUND'; END IF;
  IF r.status<>p_from_status THEN RAISE EXCEPTION 'INVALID_PREDECESSOR_STATE'; END IF;
  IF r.expected_state_version<>p_expected_state_version::bigint THEN RAISE EXCEPTION 'STALE_STATE_VERSION'; END IF;
  SELECT * INTO ds FROM governance.design_state WHERE design_state_id=r.design_state_id;
  IF ds.state_hash<>p_expected_state_hash THEN RAISE EXCEPTION 'STALE_STATE_HASH'; END IF;
  IF p_to_status NOT IN ('VERIFIED','APPROVED','REJECTED','STALE','APPLIED') THEN RAISE EXCEPTION 'INVALID_TARGET_STATE'; END IF;
  IF NOT ((p_from_status='CANDIDATE' AND p_to_status IN ('VERIFIED','REJECTED')) OR
          (p_from_status='VERIFIED' AND p_to_status IN ('APPROVED','REJECTED','STALE')) OR
          (p_from_status='APPROVED' AND p_to_status IN ('APPLIED','STALE'))) THEN
    RAISE EXCEPTION 'INVALID_STATE_TRANSITION';
  END IF;
  IF EXISTS(SELECT 1 FROM governance.transition_event WHERE entity_type='CHANGE_REQUEST' AND canonical_identity=p_canonical_identity) THEN
    SELECT transition_event_id INTO ev FROM governance.transition_event WHERE entity_type='CHANGE_REQUEST' AND canonical_identity=p_canonical_identity;
    RETURN ev;
  END IF;
  PERFORM set_config('paiforge.transition_context','CONTROLLED',true);
  UPDATE governance.change_request SET status=p_to_status WHERE change_request_id=r.change_request_id;
  INSERT INTO governance.transition_event(entity_type,entity_id,from_status,to_status,expected_state_version,expected_state_hash,canonical_identity,actor_id,authorization_ref)
  VALUES('CHANGE_REQUEST',r.change_request_id,p_from_status,p_to_status,r.expected_state_version,ds.state_hash,p_canonical_identity,p_actor_id::uuid,p_canonical_identity)
  RETURNING transition_event_id INTO ev;
  RETURN ev;
END;
$$;

CREATE OR REPLACE FUNCTION governance.transition_alternative(
  p_alternative_id text,
  p_from_status text,
  p_to_status text,
  p_canonical_identity text,
  p_actor_id text
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path=governance,core,public AS $$
DECLARE a governance.alternative%ROWTYPE; ev uuid;
BEGIN
  SELECT * INTO a FROM governance.alternative WHERE alternative_id=p_alternative_id::uuid FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'ALTERNATIVE_NOT_FOUND'; END IF;
  IF a.status<>p_from_status THEN RAISE EXCEPTION 'INVALID_PREDECESSOR_STATE'; END IF;
  IF NOT ((p_from_status='CANDIDATE' AND p_to_status IN ('FEASIBLE','INFEASIBLE','REJECTED')) OR
          (p_from_status='FEASIBLE' AND p_to_status IN ('SELECTED','REJECTED')) OR
          (p_from_status='INFEASIBLE' AND p_to_status='REJECTED')) THEN
    RAISE EXCEPTION 'INVALID_STATE_TRANSITION';
  END IF;
  IF EXISTS(SELECT 1 FROM governance.transition_event WHERE entity_type='ALTERNATIVE' AND canonical_identity=p_canonical_identity) THEN
    SELECT transition_event_id INTO ev FROM governance.transition_event WHERE entity_type='ALTERNATIVE' AND canonical_identity=p_canonical_identity;
    RETURN ev;
  END IF;
  PERFORM set_config('paiforge.transition_context','CONTROLLED',true);
  UPDATE governance.alternative SET status=p_to_status WHERE alternative_id=a.alternative_id;
  INSERT INTO governance.transition_event(entity_type,entity_id,from_status,to_status,canonical_identity,actor_id,authorization_ref)
  VALUES('ALTERNATIVE',a.alternative_id,p_from_status,p_to_status,p_canonical_identity,p_actor_id::uuid,p_canonical_identity)
  RETURNING transition_event_id INTO ev;
  RETURN ev;
END;
$$;

-- Conflict and resolution remain append-only. Their controlled functions record immutable transition evidence.
CREATE OR REPLACE FUNCTION governance.transition_conflict(
  p_conflict_id text, p_from_status text, p_to_status text, p_canonical_identity text, p_actor_id text
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path=governance,core,public AS $$
DECLARE c governance.conflict%ROWTYPE; ev uuid;
BEGIN
 SELECT * INTO c FROM governance.conflict WHERE conflict_id=p_conflict_id::uuid;
 IF NOT FOUND THEN RAISE EXCEPTION 'CONFLICT_NOT_FOUND'; END IF;
 IF c.status<>p_from_status THEN RAISE EXCEPTION 'INVALID_PREDECESSOR_STATE'; END IF;
 IF NOT (p_from_status='OPEN' AND p_to_status IN ('RESOLVED','REQUIRES_ENGINEERING_REVIEW','SUPERSEDED')) THEN RAISE EXCEPTION 'INVALID_CONFLICT_TRANSITION'; END IF;
 IF EXISTS(SELECT 1 FROM governance.transition_event WHERE entity_type='CONFLICT' AND canonical_identity=p_canonical_identity) THEN SELECT transition_event_id INTO ev FROM governance.transition_event WHERE entity_type='CONFLICT' AND canonical_identity=p_canonical_identity; RETURN ev; END IF;
 INSERT INTO governance.transition_event(entity_type,entity_id,from_status,to_status,expected_state_version,expected_state_hash,canonical_identity,actor_id,authorization_ref)
 VALUES('CONFLICT',c.conflict_id,c.status,p_to_status,c.state_version,c.state_hash,p_canonical_identity,p_actor_id::uuid,p_canonical_identity) RETURNING transition_event_id INTO ev;
 RETURN ev;
END;
$$;

CREATE OR REPLACE FUNCTION governance.transition_resolution(
  p_resolution_id text, p_from_status text, p_to_status text, p_canonical_identity text, p_actor_id text
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path=governance,core,public AS $$
DECLARE r governance.resolution%ROWTYPE; ev uuid;
BEGIN
 SELECT * INTO r FROM governance.resolution WHERE resolution_id=p_resolution_id::uuid;
 IF NOT FOUND THEN RAISE EXCEPTION 'RESOLUTION_NOT_FOUND'; END IF;
 IF r.status<>p_from_status THEN RAISE EXCEPTION 'INVALID_PREDECESSOR_STATE'; END IF;
 IF NOT (p_from_status='PROPOSED' AND p_to_status IN ('APPROVED','REJECTED','ENGINEERING_REVIEW')) THEN RAISE EXCEPTION 'INVALID_RESOLUTION_TRANSITION'; END IF;
 IF EXISTS(SELECT 1 FROM governance.transition_event WHERE entity_type='RESOLUTION' AND canonical_identity=p_canonical_identity) THEN SELECT transition_event_id INTO ev FROM governance.transition_event WHERE entity_type='RESOLUTION' AND canonical_identity=p_canonical_identity; RETURN ev; END IF;
 INSERT INTO governance.transition_event(entity_type,entity_id,from_status,to_status,canonical_identity,actor_id,authorization_ref)
 VALUES('RESOLUTION',r.resolution_id,r.status,p_to_status,p_canonical_identity,p_actor_id::uuid,p_canonical_identity) RETURNING transition_event_id INTO ev;
 RETURN ev;
END;
$$;

REVOKE UPDATE, DELETE ON governance.transition_event FROM PUBLIC;

COMMIT;
