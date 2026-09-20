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

REVOKE ALL ON SCHEMA communication_core FROM PUBLIC;
REVOKE ALL ON TABLE communication_core.task_execution FROM PUBLIC;
