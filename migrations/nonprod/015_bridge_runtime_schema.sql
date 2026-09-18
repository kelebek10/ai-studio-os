-- PAI-FORGE Bridge Runtime v1 — nonprod schema (COMM-BRIDGE-IMPLEMENT-03)
-- STATUS: NON-PRODUCTION TEST ARTIFACT — WRITTEN BUT NOT EXECUTED.
-- Claude's working environment has no network access and no PostgreSQL
-- connector (confirmed capability gap, Issue #2 comments 5727949609,
-- 5728404516). This file has NOT been run against any database,
-- including `paiforge_pg_test`. It is a design artifact for review and
-- for whoever (human/CI) has real DB access to apply and test.
-- Branch: phase-1-3-foundation
-- Target: disposable PostgreSQL 16 only, once applied by a party with
-- real DB access.

BEGIN;

CREATE SCHEMA IF NOT EXISTS bridge;

-- Reuses core.entity/event_history style, and governance.migration_ledger
-- registration pattern from migrations/nonprod/001_paiforge_v13_foundation.sql
-- rather than inventing a parallel ledger.

CREATE TABLE IF NOT EXISTS bridge.task (
  task_id text PRIMARY KEY,
  correlation_id text NOT NULL,
  logical_problem_id text NOT NULL,
  parent_task_id text REFERENCES bridge.task(task_id) ON DELETE RESTRICT,
  assigned_agent text NOT NULL,
  task_type text NOT NULL,
  scope jsonb NOT NULL,                 -- canonical token array, see P1-3
  branch text NOT NULL,
  source_commit text NOT NULL,
  policy_version text NOT NULL,
  permission_version text NOT NULL,
  round_number int NOT NULL CHECK (round_number > 0),
  state text NOT NULL CHECK (state IN (
    'TASK_CREATED','TASK_DISPATCHED','ACKNOWLEDGED','WORKING',
    'RESULT_SUBMITTED','GPT_REVIEW','VERIFIED','REWORK_REQUIRED',
    'HUMAN_ACTION_REQUIRED','BLOCKED','TIMEOUT','CLOSED')),
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bridge.ack (
  task_id text PRIMARY KEY REFERENCES bridge.task(task_id) ON DELETE RESTRICT,
  agent_id text NOT NULL,
  acknowledged_at timestamptz NOT NULL DEFAULT now()
);

-- Idempotency key corrected per P1-2: keyed on logical_problem_id +
-- artifact_digest, NOT task_id + correlation_id + artifact_digest,
-- so a resubmission under a different task_id for the same logical
-- result is still caught as a replay.
CREATE TABLE IF NOT EXISTS bridge.result (
  result_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id text NOT NULL REFERENCES bridge.task(task_id) ON DELETE RESTRICT,
  correlation_id text NOT NULL,
  logical_problem_id text NOT NULL,
  agent_id text NOT NULL,
  producer_status text NOT NULL,
  source_commit text NOT NULL,
  artifact_digest text NOT NULL,
  idempotency_key text NOT NULL UNIQUE, -- = logical_problem_id || ':' || artifact_digest
  changed_files jsonb NOT NULL,
  tests jsonb NOT NULL,
  evidence_refs jsonb NOT NULL,
  risks jsonb NOT NULL,
  gaps jsonb NOT NULL,
  recommended_next_action text,
  human_action_required boolean NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

-- Round lineage keyed ONLY by logical_problem_id (never task_id/agent/
-- branch/conversation), per AI-COMMUNICATION-LOOP-v1.0.md section 6-7.
CREATE TABLE IF NOT EXISTS bridge.round_lineage (
  logical_problem_id text PRIMARY KEY,
  highest_round int NOT NULL CHECK (highest_round >= 0 AND highest_round <= 3),
  updated_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS bridge.delegation (
  delegation_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_task_id text NOT NULL REFERENCES bridge.task(task_id) ON DELETE RESTRICT,
  correlation_id text NOT NULL,
  logical_problem_id text NOT NULL,
  specialist_id text NOT NULL,
  scope jsonb NOT NULL,
  status text NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now(),
  -- P1-3: delegation scope must be a subset of parent task scope.
  -- Enforced here defense-in-depth alongside application-layer check.
  CONSTRAINT delegation_scope_subset CHECK (
    scope <@ (SELECT scope FROM bridge.task WHERE task_id = parent_task_id)
  )
);

-- Append-only audit trail for trigger decisions (TGA-08) and all
-- bridge state transitions. Reuses governance.reject_mutation()
-- pattern from the existing foundation migration rather than a new
-- immutability mechanism.
CREATE TABLE IF NOT EXISTS bridge.audit_event (
  audit_id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  task_id text,
  event_type text NOT NULL,
  producer_identity_claim text,
  envelope_hash text,
  decision text,
  reason text,
  detail jsonb NOT NULL,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TRIGGER trg_bridge_audit_immutable
BEFORE UPDATE OR DELETE ON bridge.audit_event
FOR EACH ROW EXECUTE FUNCTION governance.reject_mutation();

CREATE TRIGGER trg_bridge_round_lineage_immutable_delete
BEFORE DELETE ON bridge.round_lineage
FOR EACH ROW EXECUTE FUNCTION governance.reject_mutation();
-- Note: UPDATE is intentionally allowed on round_lineage (the atomic
-- advancement statement in BRIDGE-RUNTIME-001 section 4 requires it);
-- only DELETE is blocked, unlike the fully-immutable governance tables.

CREATE INDEX IF NOT EXISTS ix_bridge_task_logical_problem ON bridge.task(logical_problem_id);
CREATE INDEX IF NOT EXISTS ix_bridge_result_logical_problem ON bridge.result(logical_problem_id);
CREATE INDEX IF NOT EXISTS ix_bridge_delegation_lineage ON bridge.delegation(logical_problem_id);
CREATE INDEX IF NOT EXISTS ix_bridge_audit_task ON bridge.audit_event(task_id);

-- Registers in the SAME migration_ledger as the rest of the repo
-- (governance.migration_ledger), not a parallel bridge-only ledger.
INSERT INTO governance.migration_ledger(migration_id, artifact_hash, environment)
VALUES ('015_bridge_runtime_schema', 'NONPROD-ARTIFACT-HASH-TO-BE-RECORDED', 'NONPROD')
ON CONFLICT (migration_id) DO NOTHING;

COMMIT;

-- ============================================================
-- NOT EXECUTED. Applying this migration and producing real
-- restart/replay/round-enforcement evidence requires a party with
-- actual PostgreSQL access (human or CI) — this remains a
-- CAPABILITY GAP for Claude's current working environment.
-- ============================================================
