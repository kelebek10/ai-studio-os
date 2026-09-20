-- PAI-FORGE Communication & Trigger Core v0.1
-- Non-production verification schema only.
-- Production deployment requires an explicit reviewed migration.

CREATE SCHEMA IF NOT EXISTS communication_core;

CREATE TABLE communication_core.task_execution (
    task_id uuid NOT NULL,
    correlation_id uuid NOT NULL,
    agent text NOT NULL,
    task_type text NOT NULL,
    scope text NOT NULL,
    source_commit text NOT NULL,
    status text NOT NULL CHECK (status IN ('VALIDATED','ROUTING','EXECUTING','COMPLETED','BLOCKED')),
    ack_at timestamptz,
    result jsonb NOT NULL DEFAULT '{}'::jsonb,
    evidence jsonb NOT NULL DEFAULT '[]'::jsonb,
    problem_solving_declared boolean NOT NULL DEFAULT false,
    problem_solving_round integer,
    created_at timestamptz NOT NULL DEFAULT now(),
    updated_at timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (task_id, correlation_id),
    CHECK (problem_solving_round IS NULL OR problem_solving_round BETWEEN 1 AND 3),
    CHECK (problem_solving_round IS NULL OR problem_solving_declared = true)
);

CREATE INDEX task_execution_correlation_idx
    ON communication_core.task_execution (correlation_id);

CREATE OR REPLACE FUNCTION communication_core.enforce_task_transition()
RETURNS trigger
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.status <> 'VALIDATED' THEN
        RAISE EXCEPTION 'INVALID_INITIAL_TASK_STATUS:%', NEW.status;
    END IF;

    IF TG_OP = 'UPDATE' AND NEW.status <> OLD.status THEN
        IF NOT (
            (OLD.status = 'VALIDATED' AND NEW.status = 'ROUTING') OR
            (OLD.status = 'ROUTING' AND NEW.status = 'EXECUTING') OR
            (OLD.status = 'EXECUTING' AND NEW.status IN ('COMPLETED','BLOCKED'))
        ) THEN
            RAISE EXCEPTION 'INVALID_TASK_TRANSITION:%->%', OLD.status, NEW.status;
        END IF;
    END IF;

    IF NEW.status = 'COMPLETED' AND NEW.evidence = '[]'::jsonb THEN
        RAISE EXCEPTION 'COMPLETED_REQUIRES_EVIDENCE';
    END IF;

    IF NEW.status = 'BLOCKED' AND NOT (NEW.result ? 'reason') THEN
        RAISE EXCEPTION 'BLOCKED_REQUIRES_REASON';
    END IF;

    IF NEW.ack_at IS NOT NULL AND NEW.status = 'VALIDATED' THEN
        RAISE EXCEPTION 'ACK_REQUIRES_ROUTING_OR_LATER';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER task_transition_guard
BEFORE INSERT OR UPDATE ON communication_core.task_execution
FOR EACH ROW
EXECUTE FUNCTION communication_core.enforce_task_transition();

REVOKE ALL ON SCHEMA communication_core FROM PUBLIC;
REVOKE ALL ON TABLE communication_core.task_execution FROM PUBLIC;
REVOKE ALL ON FUNCTION communication_core.enforce_task_transition() FROM PUBLIC;
