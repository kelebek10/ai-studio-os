-- PEYZAJ AI / PAI-FORGE
-- M13 Candidate Boundary / Approval Boundary
-- NONPROD ONLY. Disposable PostgreSQL evidence harness.
-- Does not modify production/Core data.

BEGIN;

DROP SCHEMA IF EXISTS m13_test CASCADE;
CREATE SCHEMA m13_test;

CREATE TABLE m13_test.design_candidate (
    id              bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    state           text NOT NULL CHECK (state IN ('CANDIDATE','VERIFIED','APPROVED')),
    actor_type      text NOT NULL CHECK (actor_type IN ('HUMAN_REVIEWER','AI','SYSTEM')),
    actor_id        text NOT NULL,
    version         integer NOT NULL DEFAULT 1,
    payload         text NOT NULL,
    created_at      timestamptz NOT NULL DEFAULT now()
);

CREATE OR REPLACE FUNCTION m13_test.enforce_boundary()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.state <> 'CANDIDATE' THEN
            RAISE EXCEPTION 'M13 boundary violation: new records must start as CANDIDATE';
        END IF;
        IF NEW.actor_type <> 'SYSTEM' THEN
            RAISE EXCEPTION 'M13 authority violation: creation actor must be SYSTEM';
        END IF;
        RETURN NEW;
    END IF;

    IF NEW.state = OLD.state THEN
        RETURN NEW;
    END IF;

    IF OLD.state = 'CANDIDATE' AND NEW.state = 'VERIFIED' THEN
        IF NEW.actor_type <> 'HUMAN_REVIEWER' THEN
            RAISE EXCEPTION 'M13 authority violation: CANDIDATE to VERIFIED requires HUMAN_REVIEWER';
        END IF;
        RETURN NEW;
    END IF;

    IF OLD.state = 'VERIFIED' AND NEW.state = 'APPROVED' THEN
        IF NEW.actor_type <> 'HUMAN_REVIEWER' THEN
            RAISE EXCEPTION 'M13 authority violation: VERIFIED to APPROVED requires HUMAN_REVIEWER';
        END IF;
        RETURN NEW;
    END IF;

    RAISE EXCEPTION 'M13 boundary violation: invalid transition % -> %', OLD.state, NEW.state;
END;
$$;

CREATE TRIGGER trg_m13_boundary
BEFORE INSERT OR UPDATE ON m13_test.design_candidate
FOR EACH ROW EXECUTE FUNCTION m13_test.enforce_boundary();

-- T01: valid CANDIDATE creation
INSERT INTO m13_test.design_candidate (state, actor_type, actor_id, payload)
VALUES ('CANDIDATE','SYSTEM','system-test','candidate-001');

DO $$
BEGIN
    IF (SELECT state FROM m13_test.design_candidate WHERE id = 1) = 'CANDIDATE' THEN
        RAISE NOTICE 'M13 T01 PASS: valid CANDIDATE creation accepted';
    ELSE
        RAISE EXCEPTION 'M13 T01 FAIL';
    END IF;
END;
$$;

-- T02: CANDIDATE -> APPROVED must reject
DO $$
BEGIN
    BEGIN
        UPDATE m13_test.design_candidate
        SET state='APPROVED', actor_type='HUMAN_REVIEWER', actor_id='human-test'
        WHERE id=1;
        RAISE EXCEPTION 'M13 T02 FAIL: direct CANDIDATE -> APPROVED accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'M13 boundary violation:%' THEN
            RAISE NOTICE 'M13 T02 PASS: direct CANDIDATE -> APPROVED rejected';
        ELSE
            RAISE;
        END IF;
    END;
END;
$$;

-- T03: CANDIDATE -> VERIFIED with HUMAN_REVIEWER must pass
UPDATE m13_test.design_candidate
SET state='VERIFIED', actor_type='HUMAN_REVIEWER', actor_id='human-test', version=2
WHERE id=1;

DO $$
BEGIN
    IF (SELECT state FROM m13_test.design_candidate WHERE id=1) = 'VERIFIED' THEN
        RAISE NOTICE 'M13 T03 PASS: HUMAN_REVIEWER verification accepted';
    ELSE
        RAISE EXCEPTION 'M13 T03 FAIL';
    END IF;
END;
$$;

-- T04: VERIFIED -> APPROVED by AI must reject
DO $$
BEGIN
    BEGIN
        UPDATE m13_test.design_candidate
        SET state='APPROVED', actor_type='AI', actor_id='ai-test'
        WHERE id=1;
        RAISE EXCEPTION 'M13 T04 FAIL: AI approval accepted';
    EXCEPTION WHEN OTHERS THEN
        IF SQLERRM LIKE 'M13 authority violation:%' THEN
            RAISE NOTICE 'M13 T04 PASS: AI approval rejected';
        ELSE
            RAISE;
        END IF;
    END;
END;
$$;

-- T05: VERIFIED -> APPROVED by HUMAN_REVIEWER must pass
UPDATE m13_test.design_candidate
SET state='APPROVED', actor_type='HUMAN_REVIEWER', actor_id='human-test', version=3
WHERE id=1;

DO $$
BEGIN
    IF (SELECT state FROM m13_test.design_candidate WHERE id=1) = 'APPROVED' THEN
        RAISE NOTICE 'M13 T05 PASS: HUMAN_REVIEWER approval accepted';
    ELSE
        RAISE EXCEPTION 'M13 T05 FAIL';
    END IF;
END;
$$;

-- T06: rollback integrity; invalid transition must not change committed state
DO $$
DECLARE
    before_state text;
BEGIN
    before_state := (SELECT state FROM m13_test.design_candidate WHERE id=1);
    BEGIN
        UPDATE m13_test.design_candidate
        SET state='CANDIDATE', actor_type='SYSTEM', actor_id='system-test'
        WHERE id=1;
    EXCEPTION WHEN OTHERS THEN
        NULL;
    END;
    IF (SELECT state FROM m13_test.design_candidate WHERE id=1) <> before_state THEN
        RAISE EXCEPTION 'M13 T06 FAIL: state changed after rejected transition';
    END IF;
    RAISE NOTICE 'M13 T06 PASS: rejected transition preserved state';
END;
$$;

DO $$
BEGIN
    RAISE NOTICE 'M13 CANDIDATE / APPROVAL BOUNDARY PILOT COMPLETE';
END;
$$;

ROLLBACK;
