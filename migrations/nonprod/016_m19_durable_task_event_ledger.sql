-- PAI-FORGE M19.3 non-production durable task/event ledger
-- DESIGN IMPLEMENTATION ONLY. Never execute against production.
BEGIN;

CREATE SCHEMA IF NOT EXISTS m19_control;

CREATE TABLE m19_control.task (
  task_id uuid PRIMARY KEY,
  correlation_id uuid NOT NULL,
  parent_task_id uuid NULL REFERENCES m19_control.task(task_id) ON DELETE RESTRICT,
  task_type text NOT NULL,
  agent_id text NOT NULL,
  scope text NOT NULL,
  source_commit text NOT NULL,
  status text NOT NULL CHECK (status IN ('CREATED','ASSIGNED','ACKNOWLEDGED','VALIDATED','ROUTING','EXECUTING','REVIEW','EVIDENCE','RESULT_SUBMITTED','VERIFIED','REWORK_REQUIRED','BLOCKED','HUMAN_ACTION_REQUIRED','COMPLETED','CLOSED')),
  current_sequence bigint NOT NULL DEFAULT 0 CHECK (current_sequence >= 0),
  conflict_round integer NOT NULL DEFAULT 0 CHECK (conflict_round BETWEEN 0 AND 3),
  requires_human boolean NOT NULL DEFAULT false,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE m19_control.task_idempotency (
  idempotency_id uuid PRIMARY KEY,
  task_id uuid NULL REFERENCES m19_control.task(task_id) ON DELETE RESTRICT,
  command_type text NOT NULL,
  idempotency_key text NOT NULL,
  request_digest text NOT NULL,
  outcome_digest text NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(command_type,idempotency_key)
);

CREATE TABLE m19_control.task_event (
  event_id uuid PRIMARY KEY,
  task_id uuid NOT NULL REFERENCES m19_control.task(task_id) ON DELETE RESTRICT,
  correlation_id uuid NOT NULL,
  causation_id uuid NULL REFERENCES m19_control.task_event(event_id) ON DELETE RESTRICT,
  sequence_no bigint NOT NULL CHECK (sequence_no > 0),
  event_type text NOT NULL,
  actor_type text NOT NULL,
  actor_id text NOT NULL,
  source_commit text NOT NULL,
  scope text NOT NULL,
  payload jsonb NULL,
  payload_digest text NOT NULL,
  idempotency_key text NOT NULL,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  UNIQUE(task_id,sequence_no),
  UNIQUE(task_id,event_type,idempotency_key)
);

CREATE TABLE m19_control.task_attempt (
  attempt_id uuid PRIMARY KEY,
  task_id uuid NOT NULL REFERENCES m19_control.task(task_id) ON DELETE RESTRICT,
  attempt_no integer NOT NULL CHECK (attempt_no > 0),
  executor_id text NOT NULL,
  source_commit text NOT NULL,
  started_at timestamptz NOT NULL,
  acknowledged_at timestamptz NULL,
  finished_at timestamptz NULL,
  status text NOT NULL,
  result_digest text NULL,
  UNIQUE(task_id,attempt_no)
);

CREATE TABLE m19_control.task_handoff (
  handoff_id uuid PRIMARY KEY,
  task_id uuid NOT NULL REFERENCES m19_control.task(task_id) ON DELETE RESTRICT,
  attempt_id uuid NULL REFERENCES m19_control.task_attempt(attempt_id) ON DELETE RESTRICT,
  handoff_type text NOT NULL,
  source_actor text NOT NULL,
  target_actor text NOT NULL,
  artifact_digest text NULL,
  evidence_digest text NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX task_correlation_idx ON m19_control.task(correlation_id);
CREATE INDEX task_status_idx ON m19_control.task(status);
CREATE INDEX task_agent_status_idx ON m19_control.task(agent_id,status);
CREATE INDEX task_parent_idx ON m19_control.task(parent_task_id);
CREATE INDEX event_task_sequence_idx ON m19_control.task_event(task_id,sequence_no);
CREATE INDEX event_correlation_time_idx ON m19_control.task_event(correlation_id,occurred_at);
CREATE INDEX event_idempotency_idx ON m19_control.task_event(idempotency_key);
CREATE INDEX attempt_task_no_idx ON m19_control.task_attempt(task_id,attempt_no);
CREATE INDEX handoff_task_time_idx ON m19_control.task_handoff(task_id,created_at);

COMMIT;
