"""
COMM-BRIDGE-IMPLEMENT-05 — restart-persistence test, VERIFY phase.

STATUS: WRITTEN, NOT EXECUTED. Run this AFTER restart_test_write_phase.py
and AFTER restarting the Postgres container (without deleting its
volume — see that file's docstring for the exact commands). This
script re-opens a fresh connection (simulating the post-restart
client) and checks that every piece of state phase 1 wrote is still
present, unchanged, and still enforced (round 4 still denied, replay
still denied) — persistence AND continued enforcement, not just row
existence.

    DATABASE_URL=postgresql://bridge_test:bridge_test@localhost:55432/paiforge_bridge_test \
      python tests/bridge-runtime/postgres_integration/restart_test_verify_phase.py

Exit code 0 = all checks passed. Nonzero = printed failure detail.
This is the actual evidence file for the P1-1/P1-2/P1-3 "restart
sonrası state/replay/delegation persistence" requirement — its
console output (or a saved copy of it) is the evidence artifact, not
a claim in this repo's markdown.
"""
from __future__ import annotations
import os
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pg_conn import get_connection
from restart_test_write_phase import (
    FIXED_LP_ROUND, FIXED_LP_REPLAY, FIXED_DIGEST, FIXED_TASK_PARENT, FIXED_TASK_REPLAY,
)


def main() -> int:
    conn = get_connection()
    failures = []

    def check(label, condition):
        status = "PASS" if condition else "FAIL"
        print(f"[{status}] {label}")
        if not condition:
            failures.append(label)

    try:
        # 1. round_lineage row survived with the exact value written pre-restart
        with conn.cursor() as cur:
            cur.execute(
                "SELECT highest_round FROM bridge.round_lineage WHERE logical_problem_id=%s",
                (FIXED_LP_ROUND,),
            )
            row = cur.fetchone()
        check("round_lineage row exists after restart", row is not None)
        if row:
            check("round_lineage value unchanged after restart (== 2)", row[0] == 2)

        # 2. round enforcement STILL works post-restart (round 3 succeeds, round 4 still denied)
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO bridge.round_lineage (logical_problem_id, highest_round)
                VALUES (%s, 3)
                ON CONFLICT (logical_problem_id) DO UPDATE
                SET highest_round = EXCLUDED.highest_round, updated_at = now()
                WHERE bridge.round_lineage.highest_round < EXCLUDED.highest_round
                  AND EXCLUDED.highest_round <= 3
                RETURNING highest_round;
                """,
                (FIXED_LP_ROUND,),
            )
            advanced_to_3 = cur.fetchone()
        conn.commit()
        check("round advance to 3 still works after restart", advanced_to_3 is not None and advanced_to_3[0] == 3)

        denied = None
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO bridge.round_lineage (logical_problem_id, highest_round)
                    VALUES (%s, 4)
                    ON CONFLICT (logical_problem_id) DO UPDATE
                    SET highest_round = EXCLUDED.highest_round, updated_at = now()
                    WHERE bridge.round_lineage.highest_round < EXCLUDED.highest_round
                      AND EXCLUDED.highest_round <= 3
                    RETURNING highest_round;
                    """,
                    (FIXED_LP_ROUND,),
                )
                denied = cur.fetchone()
            conn.commit()
        except Exception as exc:
            conn.rollback()
            # The table CHECK is the DB-layer defense-in-depth denial.
            # Both the atomic WHERE guard and the CHECK may reject round 4.
            if getattr(exc, "pgcode", None) != "23514":
                raise
        check("round 4 still deterministically denied after restart", denied is None)

        # 3. result/idempotency row survived
        idempotency_key = f"{FIXED_LP_REPLAY}:{FIXED_DIGEST}"
        with conn.cursor() as cur:
            cur.execute(
                "SELECT count(*) FROM bridge.result WHERE idempotency_key=%s", (idempotency_key,)
            )
            count = cur.fetchone()[0]
        check("result row exists after restart", count == 1)

        # 4. replay protection STILL works post-restart (same key, different task)
        with conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO bridge.task (
                    task_id, correlation_id, logical_problem_id, assigned_agent,
                    task_type, scope, branch, source_commit, policy_version,
                    permission_version, round_number, state
                ) VALUES ('T-RESTART-REPLAY-ATTEMPT', 'C-RESTART-2', %s, 'AGENT-CLAUDE-001',
                          'IMPLEMENTATION', '[]'::jsonb, 'feature/comm-bridge-runtime-v1',
                          '921f37d49180052af6ed9b41b190822cc4ffd866', 'v1.0', 'v1.0',
                          1, 'RESULT_SUBMITTED')
                ON CONFLICT (task_id) DO NOTHING
                """,
                (FIXED_LP_REPLAY,),
            )
        conn.commit()
        replay_rejected = False
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO bridge.result (
                        task_id, correlation_id, logical_problem_id, agent_id,
                        producer_status, source_commit, artifact_digest, idempotency_key,
                        changed_files, tests, evidence_refs, risks, gaps,
                        recommended_next_action, human_action_required
                    ) VALUES ('T-RESTART-REPLAY-ATTEMPT', 'C-RESTART-2', %s, 'AGENT-CLAUDE-001',
                              'SUBMITTED', '921f37d49180052af6ed9b41b190822cc4ffd866', %s, %s,
                              '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, '[]'::jsonb,
                              NULL, false)
                    """,
                    (FIXED_LP_REPLAY, FIXED_DIGEST, idempotency_key),
                )
            conn.commit()
        except Exception:
            conn.rollback()
            replay_rejected = True
        check("replay still rejected after restart (different task_id, same idempotency_key)", replay_rejected)

        # 5. delegation row survived
        with conn.cursor() as cur:
            cur.execute(
                "SELECT count(*) FROM bridge.delegation WHERE parent_task_id=%s", (FIXED_TASK_PARENT,)
            )
            count = cur.fetchone()[0]
        check("delegation row exists after restart", count == 1)

        # 6. delegation scope constraint STILL enforced post-restart
        scope_still_enforced = False
        try:
            with conn.cursor() as cur:
                cur.execute(
                    """
                    INSERT INTO bridge.delegation (
                        parent_task_id, correlation_id, logical_problem_id,
                        specialist_id, scope, status
                    ) VALUES (%s, 'C-RESTART-3', %s, 'AGENT-SPECIALIST-002',
                              '["write:task_result"]'::jsonb, 'CREATED')
                    """,
                    (FIXED_TASK_PARENT, FIXED_LP_ROUND),
                )
            conn.commit()
        except Exception:
            conn.rollback()
            scope_still_enforced = True
        check("delegation_scope_subset CHECK still enforced after restart", scope_still_enforced)

    finally:
        conn.close()

    print()
    if failures:
        print(f"RESTART TEST: {len(failures)} FAILURE(S): {failures}")
        return 1
    print("RESTART TEST: ALL CHECKS PASS")
    return 0


if __name__ == "__main__":
    sys.exit(main())
