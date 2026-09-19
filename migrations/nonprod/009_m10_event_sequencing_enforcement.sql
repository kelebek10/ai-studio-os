-- PAI-FORGE M10 EVENT SEQUENCING ENFORCEMENT v1.0
-- Disposable PostgreSQL only. Never production.
-- Adds deterministic per-entity event ordering and immutable transition evidence.

BEGIN;

ALTER TABLE governance.transition_event
  ADD COLUMN IF NOT EXISTS event_sequence bigint;

-- Backfill existing non-production evidence deterministically before enforcing NOT NULL.
WITH ranked AS (
  SELECT transition_event_id,
         row_number() OVER (
           PARTITION BY entity_type, entity_id
           ORDER BY created_at, transition_event_id
         )::bigint AS seq
  FROM governance.transition_event
)
UPDATE governance.transition_event e
SET event_sequence = ranked.seq
FROM ranked
WHERE e.transition_event_id = ranked.transition_event_id
  AND e.event_sequence IS NULL;

ALTER TABLE governance.transition_event
  ALTER COLUMN event_sequence SET NOT NULL;

CREATE UNIQUE INDEX IF NOT EXISTS uq_transition_event_entity_sequence
  ON governance.transition_event(entity_type, entity_id, event_sequence);

CREATE OR REPLACE FUNCTION governance.next_transition_event_sequence(
  p_entity_type text,
  p_entity_id uuid
) RETURNS bigint
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = governance, pg_catalog AS $$
DECLARE v_next bigint;
BEGIN
  -- Transaction-scoped advisory lock serializes allocation for one governed entity.
  PERFORM pg_advisory_xact_lock(
    hashtextextended(p_entity_type || ':' || p_entity_id::text, 0)
  );

  SELECT COALESCE(MAX(event_sequence), 0) + 1
    INTO v_next
  FROM governance.transition_event
  WHERE entity_type = p_entity_type
    AND entity_id = p_entity_id;

  RETURN v_next;
END;
$$;

CREATE OR REPLACE FUNCTION governance.transition_event_immutable_guard()
RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  RAISE EXCEPTION 'IMMUTABLE_TRANSITION_EVENT: UPDATE/DELETE is forbidden';
END;
$$;

DROP TRIGGER IF EXISTS transition_event_immutable_guard ON governance.transition_event;
CREATE TRIGGER transition_event_immutable_guard
BEFORE UPDATE OR DELETE ON governance.transition_event
FOR EACH ROW EXECUTE FUNCTION governance.transition_event_immutable_guard();

-- Harden all four M08 transition functions so every emitted event gets a deterministic sequence.
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
DECLARE r governance.change_request%ROWTYPE; ds governance.design_state%ROWTYPE; ev uuid; seq bigint;
BEGIN
  SELECT * INTO r FROM governance.change_request WHERE request_key=p_request_key FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'CHANGE_REQUEST_NOT_FOUND'; END IF;
  IF EXISTS(SELECT 1 FROM governance.transition_event WHERE entity_type='CHANGE_REQUEST' AND canonical_identity=p_canonical_identity) THEN
    SELECT transition_event_id INTO ev FROM governance.transition_event WHERE entity_type='CHANGE_REQUEST' AND canonical_identity=p_canonical_identity;
    RETURN ev;
  END IF;
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
  seq := governance.next_transition_event_sequence('CHANGE_REQUEST',r.change_request_id);
  PERFORM set_config('paiforge.transition_context','CONTROLLED',true);
  UPDATE governance.change_request SET status=p_to_status WHERE change_request_id=r.change_request_id;
  PERFORM set_config('paiforge.transition_context','',true);
  INSERT INTO governance.transition_event(entity_type,entity_id,event_sequence,from_status,to_status,expected_state_version,expected_state_hash,canonical_identity,actor_id,authorization_ref)
  VALUES('CHANGE_REQUEST',r.change_request_id,seq,p_from_status,p_to_status,r.expected_state_version,ds.state_hash,p_canonical_identity,p_actor_id::uuid,p_canonical_identity)
  RETURNING transition_event_id INTO ev;
  RETURN ev;
END;
$$;

CREATE OR REPLACE FUNCTION governance.transition_alternative(
  p_alternative_id text,p_from_status text,p_to_status text,p_canonical_identity text,p_actor_id text
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path=governance,core,public AS $$
DECLARE a governance.alternative%ROWTYPE; ev uuid; seq bigint;
BEGIN
  SELECT * INTO a FROM governance.alternative WHERE alternative_id=p_alternative_id::uuid FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'ALTERNATIVE_NOT_FOUND'; END IF;
  IF EXISTS(SELECT 1 FROM governance.transition_event WHERE entity_type='ALTERNATIVE' AND canonical_identity=p_canonical_identity) THEN
    SELECT transition_event_id INTO ev FROM governance.transition_event WHERE entity_type='ALTERNATIVE' AND canonical_identity=p_canonical_identity;
    RETURN ev;
  END IF;
  IF a.status<>p_from_status THEN RAISE EXCEPTION 'INVALID_PREDECESSOR_STATE'; END IF;
  IF NOT ((p_from_status='CANDIDATE' AND p_to_status IN ('FEASIBLE','INFEASIBLE','REJECTED')) OR
          (p_from_status='FEASIBLE' AND p_to_status IN ('SELECTED','REJECTED')) OR
          (p_from_status='INFEASIBLE' AND p_to_status='REJECTED')) THEN RAISE EXCEPTION 'INVALID_STATE_TRANSITION'; END IF;
  seq := governance.next_transition_event_sequence('ALTERNATIVE',a.alternative_id);
  PERFORM set_config('paiforge.transition_context','CONTROLLED',true);
  UPDATE governance.alternative SET status=p_to_status WHERE alternative_id=a.alternative_id;
  PERFORM set_config('paiforge.transition_context','',true);
  INSERT INTO governance.transition_event(entity_type,entity_id,event_sequence,from_status,to_status,canonical_identity,actor_id,authorization_ref)
  VALUES('ALTERNATIVE',a.alternative_id,seq,p_from_status,p_to_status,p_canonical_identity,p_actor_id::uuid,p_canonical_identity)
  RETURNING transition_event_id INTO ev;
  RETURN ev;
END;
$$;

CREATE OR REPLACE FUNCTION governance.transition_conflict(
  p_conflict_id text,p_from_status text,p_to_status text,p_canonical_identity text,p_actor_id text
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path=governance,core,public AS $$
DECLARE c governance.conflict%ROWTYPE; ev uuid; seq bigint;
BEGIN
 SELECT * INTO c FROM governance.conflict WHERE conflict_id=p_conflict_id::uuid;
 IF NOT FOUND THEN RAISE EXCEPTION 'CONFLICT_NOT_FOUND'; END IF;
 IF EXISTS(SELECT 1 FROM governance.transition_event WHERE entity_type='CONFLICT' AND canonical_identity=p_canonical_identity) THEN SELECT transition_event_id INTO ev FROM governance.transition_event WHERE entity_type='CONFLICT' AND canonical_identity=p_canonical_identity; RETURN ev; END IF;
 IF c.status<>p_from_status THEN RAISE EXCEPTION 'INVALID_PREDECESSOR_STATE'; END IF;
 IF NOT (p_from_status='OPEN' AND p_to_status IN ('RESOLVED','REQUIRES_ENGINEERING_REVIEW','SUPERSEDED')) THEN RAISE EXCEPTION 'INVALID_CONFLICT_TRANSITION'; END IF;
 seq := governance.next_transition_event_sequence('CONFLICT',c.conflict_id);
 INSERT INTO governance.transition_event(entity_type,entity_id,event_sequence,from_status,to_status,expected_state_version,expected_state_hash,canonical_identity,actor_id,authorization_ref)
 VALUES('CONFLICT',c.conflict_id,seq,c.status,p_to_status,c.state_version,c.state_hash,p_canonical_identity,p_actor_id::uuid,p_canonical_identity) RETURNING transition_event_id INTO ev;
 RETURN ev;
END;
$$;

CREATE OR REPLACE FUNCTION governance.transition_resolution(
  p_resolution_id text,p_from_status text,p_to_status text,p_canonical_identity text,p_actor_id text
) RETURNS uuid
LANGUAGE plpgsql SECURITY DEFINER SET search_path=governance,core,public AS $$
DECLARE r governance.resolution%ROWTYPE; ev uuid; seq bigint;
BEGIN
 SELECT * INTO r FROM governance.resolution WHERE resolution_id=p_resolution_id::uuid;
 IF NOT FOUND THEN RAISE EXCEPTION 'RESOLUTION_NOT_FOUND'; END IF;
 IF EXISTS(SELECT 1 FROM governance.transition_event WHERE entity_type='RESOLUTION' AND canonical_identity=p_canonical_identity) THEN SELECT transition_event_id INTO ev FROM governance.transition_event WHERE entity_type='RESOLUTION' AND canonical_identity=p_canonical_identity; RETURN ev; END IF;
 IF r.status<>p_from_status THEN RAISE EXCEPTION 'INVALID_PREDECESSOR_STATE'; END IF;
 IF NOT (p_from_status='PROPOSED' AND p_to_status IN ('APPROVED','REJECTED','ENGINEERING_REVIEW')) THEN RAISE EXCEPTION 'INVALID_RESOLUTION_TRANSITION'; END IF;
 seq := governance.next_transition_event_sequence('RESOLUTION',r.resolution_id);
 INSERT INTO governance.transition_event(entity_type,entity_id,event_sequence,from_status,to_status,canonical_identity,actor_id,authorization_ref)
 VALUES('RESOLUTION',r.resolution_id,seq,r.status,p_to_status,p_canonical_identity,p_actor_id::uuid,p_canonical_identity) RETURNING transition_event_id INTO ev;
 RETURN ev;
END;
$$;

COMMIT;
