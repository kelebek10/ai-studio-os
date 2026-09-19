"""
COMM-BRIDGE-IMPLEMENT-05 — restart-persistence test, WRITE phase.

STATUS: WRITTEN, NOT EXECUTED. Cannot be run in Claude's working
environment (no Docker, no network — confirmed this task). This is a
two-phase manual/CI procedure because an automated pytest process
cannot restart its own database container mid-test-run. The party
running this must:

  1. `docker compose -f infra/nonprod/docker-compose.postgres.yml up -d`
     and apply migrations 001..015 (see that file's header comment).
  2. Run this script (phase 1 — WRITE):
       DATABASE_URL=postgresql://bridge_test:bridge_test@localhost:55432/paiforge_bridge_test \
         python tests/bridge-runtime/postgres_integration/restart_test_write_phase.py
  3. Restart the container WITHOUT deleting its volume:
       docker compose -f infra/nonprod/docker-compose.postgres.yml restart postgres
     (NEVER `down -v` between phases — that deletes the volume this
     test is trying to prove survives a restart.)
  4. Run restart_test_verify_phase.py (phase 2 — VERIFY) with the
     SAME lineage IDs this script printed.

This script and its phase-2 counterpart are the actual restart-
persistence evidence requested by COMM-BRIDGE-IMPLEMENT-05 — the
serialize/reload "MODEL ONLY" tests in
bridge-runtime/round_lineage.py and replay_consumption.py
(COMM-BRIDGE-IMPLEMENT-04) explicitly are NOT this, and this script's
existence does not retroactively upgrade those algorithm-level tests
to real-Postgres restart evidence (AC-02).
"""
from __future__ import annotations
import json
import os
import sys
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pg_conn import get_connection, truncate_bridge_tables

# Not using truncate here on repeat runs would break the fixed-ID
# contract below — this script truncates bridge.* ONCE at the start
# of phase 1 so the IDs it prints are guaranteed fresh and unambiguous.

FIXED_LP_ROUND = "LP-RESTART-TEST-ROUND"
FIXED_LP_REPLAY = "LP-RESTART-TEST-REPLAY"
FIXED_DIGEST = "restart-test-digest"
FIXED_TASK_PARENT = "T-RESTART-TEST-PARENT"
FIXED_TASK_REPLAY = "T-RESTART-TEST-REPLAY"


def main():
    conn = get_connection()
    try:
        truncate_bridge_tables(conn)

        # --- round_lineage state: advance to round 2 (not 3, so phase 2
        # can also confirm round 4 is STILL denied after restart, not
        # just that the row exists) ---
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO bridge.round_lineage (logical_problem_id, highest_round)
                VALUES (%s, 2)
                """,
                (FIXED_LP_ROUND,),
            )

        # --- replay/result state ---
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO bridge.task (
                    task_id, correlation_id, logical_problem_id, assigned_agent,
                    task_type, scope, branch, source_commit, policy_version,
                    permission_version, round_number, state
                ) VALUES (%s, 'C-RESTART', %s, 'AGENT-CLAUDE-001', 'IMPLEMENTATION',
                          '[]'::jsonb, 'feature/comm-bridge-runtime-v1',
                          '921f37d49180052af6ed9b41b190822cc4ffd866', 'v1.0', 'v1.0',
                          1, 'RESULT_SUBMITTED')
                """,
                (FIXED_TASK_REPLAY, FIXED_LP_REPLAY),
            )
            idempotency_key = f"{FIXED_LP_REPLAY}:{FIXED_DIGEST}"
            cur.execute(
                """
                INSERT INTO bridge.result (
                    task_id, correlation_id, logical_problem_id, agent_id,
                    producer_status, source_commit, artifact_digest, idempotency_key,
                    changed_files, tests, evidence_refs, risks, gaps,
                    recommended_next_action, human_action_required
                ) VALUES (%s, 'C-RESTART', %s, 'AGENT-CLAUDE-001', 'SUBMITTED',
                          '921f37d49180052af6ed9b41b190822cc4ffd866', %s, %s,
                          '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, '[]'::jsonb,
                          NULL, false)
                """,
                (FIXED_TASK_REPLAY, FIXED_LP_REPLAY, FIXED_DIGEST, idempotency_key),
            )

        # --- delegation state ---
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO bridge.task (
                    task_id, correlation_id, logical_problem_id, assigned_agent,
                    task_type, scope, branch, source_commit, policy_version,
                    permission_version, round_number, state
                ) VALUES (%s, 'C-RESTART-DELEGATION', %s, 'AGENT-CLAUDE-001', 'IMPLEMENTATION',
                          '["read:evidence"]'::jsonb, 'feature/comm-bridge-runtime-v1',
                          '921f37d49180052af6ed9b41b190822cc4ffd866', 'v1.0', 'v1.0',
                          1, 'WORKING')
                """,
                (FIXED_TASK_PARENT, FIXED_LP_ROUND),
            )
            cur.execute(
                """
                INSERT INTO bridge.delegation (
                    parent_task_id, correlation_id, logical_problem_id,
                    specialist_id, scope, status
                ) VALUES (%s, 'C-RESTART-DELEGATION', %s, 'AGENT-SPECIALIST-001',
                          '["read:evidence"]'::jsonb, 'CREATED')
                """,
                (FIXED_TASK_PARENT, FIXED_LP_ROUND),
            )

        conn.commit()

        print("WRITE PHASE COMPLETE. State written:")
        print(json.dumps({
            "round_lineage": {FIXED_LP_ROUND: 2},
            "result_idempotency_key": idempotency_key,
            "delegation_parent_task": FIXED_TASK_PARENT,
        }, indent=2))
        print("\nNow restart the Postgres container (without deleting its volume) and run "
              "restart_test_verify_phase.py.")
    finally:
        conn.close()


if __name__ == "__main__":
    main()
