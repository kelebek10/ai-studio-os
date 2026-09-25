-- M19.4 non-production dispatcher/ACK/lease schema
BEGIN;
CREATE TABLE IF NOT EXISTS m19_control.task_assignment (
 assignment_id uuid PRIMARY KEY, task_id uuid NOT NULL REFERENCES m19_control.task(task_id) ON DELETE RESTRICT,
 executor_id text NOT NULL, scope text NOT NULL, capability text NOT NULL, registry_status text NOT NULL,
 assigned_at timestamptz NOT NULL DEFAULT now(), status text NOT NULL CHECK(status IN ('ACTIVE','ACKNOWLEDGED','EXPIRED','RECOVERED','REJECTED')),
 idempotency_key text NOT NULL, UNIQUE(task_id,idempotency_key)
);
CREATE TABLE IF NOT EXISTS m19_control.task_lease (
 lease_id uuid PRIMARY KEY, task_id uuid NOT NULL REFERENCES m19_control.task(task_id) ON DELETE RESTRICT,
 attempt_id uuid NOT NULL REFERENCES m19_control.task_attempt(attempt_id) ON DELETE RESTRICT,
 executor_id text NOT NULL, issued_at timestamptz NOT NULL DEFAULT now(), expires_at timestamptz NOT NULL,
 heartbeat_at timestamptz NULL, status text NOT NULL CHECK(status IN ('ACTIVE','EXPIRED','RELEASED'))
);
CREATE UNIQUE INDEX IF NOT EXISTS task_one_active_lease ON m19_control.task_lease(task_id) WHERE status='ACTIVE';
COMMIT;