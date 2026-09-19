"""
COMM-BRIDGE-IMPLEMENT-05 — P1-1 REAL PostgreSQL integration tests.

STATUS: WRITTEN, NOT EXECUTED. This module has never been run against
a real database in Claude's working environment (no network egress,
no psycopg2, no DB connector — confirmed this task via `tool_search`
and a failed `apt-get install postgresql`, both logged in
governance/BRIDGE-RUNTIME-V1-POSTGRES-READINESS-v1.0.md). Do not cite
any result from this file as PASS unless it was actually executed
against a real Postgres 16 instance and the executor can produce the
psql/pytest output as evidence (AC-01, AC-02).

Uses the EXACT atomic statement from
governance/BRIDGE-RUNTIME-V1-PREREQUISITES-v1.0.md section 4
(INSERT ... ON CONFLICT ... WHERE ... <= 3 guard) — this is not a
reimplementation, it is the literal contract SQL, so a PASS here is
evidence for that contract's SQL, not a different query invented to
make the test pass (AC-05).

Run with:
    DATABASE_URL=postgresql://bridge_test:bridge_test@localhost:55432/paiforge_bridge_test \
      pytest tests/bridge-runtime/postgres_integration/test_round_lineage_pg.py -v
"""
from __future__ import annotations
import os
import sys
import threading
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pg_conn import get_connection, truncate_bridge_tables

# The exact contract statement from BRIDGE-RUNTIME-001 section 4,
# combining first-insert and atomic-advance in one statement.
ADVANCE_ROUND_SQL = """
INSERT INTO bridge.round_lineage (logical_problem_id, highest_round)
VALUES (%s, %s)
ON CONFLICT (logical_problem_id) DO UPDATE
SET highest_round = EXCLUDED.highest_round, updated_at = now()
WHERE bridge.round_lineage.highest_round < EXCLUDED.highest_round
  AND EXCLUDED.highest_round <= 3
RETURNING highest_round;
"""


def advance_round(conn, logical_problem_id: str, new_round: int) -> int | None:
    """Returns the new highest_round on success, or None if the
    statement affected zero rows (round limit exceeded or stale/
    non-monotonic — per BRIDGE-RUNTIME-001 section 4, this MUST be
    treated as BLOCKED / ROUND_LIMIT_OR_STALE by the caller, never
    retried with a different query)."""
    with conn.cursor() as cur:
        cur.execute(ADVANCE_ROUND_SQL, (logical_problem_id, new_round))
        row = cur.fetchone()
    conn.commit()
    return row[0] if row else None


def current_round(conn, logical_problem_id: str) -> int:
    with conn.cursor() as cur:
        cur.execute(
            "SELECT highest_round FROM bridge.round_lineage WHERE logical_problem_id = %s",
            (logical_problem_id,),
        )
        row = cur.fetchone()
    return row[0] if row else 0


def test_pg_monotonic_advance():
    conn = get_connection()
    try:
        truncate_bridge_tables(conn)
        lp = f"LP-PG-{uuid.uuid4()}"
        assert advance_round(conn, lp, 1) == 1
        assert advance_round(conn, lp, 2) == 2
        assert current_round(conn, lp) == 2
    finally:
        conn.close()


def test_pg_stale_transition_returns_zero_rows():
    conn = get_connection()
    try:
        truncate_bridge_tables(conn)
        lp = f"LP-PG-{uuid.uuid4()}"
        advance_round(conn, lp, 2)
        # Attempting round 2 again (not > current) must affect zero rows
        result = advance_round(conn, lp, 2)
        assert result is None
        assert current_round(conn, lp) == 2  # unchanged
    finally:
        conn.close()


def test_pg_round4_deterministically_denied():
    conn = get_connection()
    try:
        truncate_bridge_tables(conn)
        lp = f"LP-PG-{uuid.uuid4()}"
        advance_round(conn, lp, 1)
        advance_round(conn, lp, 2)
        advance_round(conn, lp, 3)
        result = advance_round(conn, lp, 4)  # violates EXCLUDED.highest_round <= 3
        assert result is None
        assert current_round(conn, lp) == 3
    finally:
        conn.close()


def test_pg_check_constraint_rejects_round_above_3_directly():
    """Defense in depth: even bypassing advance_round() and inserting
    directly, the table's own CHECK(highest_round <= 3) must reject
    round 4 — this is the constraint in 015_bridge_runtime_schema.sql
    itself, not application logic."""
    conn = get_connection()
    try:
        truncate_bridge_tables(conn)
        lp = f"LP-PG-{uuid.uuid4()}"
        raised = False
        try:
            with conn.cursor() as cur:
                cur.execute(
                    "INSERT INTO bridge.round_lineage (logical_problem_id, highest_round) "
                    "VALUES (%s, %s)",
                    (lp, 4),
                )
            conn.commit()
        except Exception:
            conn.rollback()
            raised = True
        assert raised, "CHECK(highest_round <= 3) did not reject a direct round=4 insert"
    finally:
        conn.close()


def test_pg_concurrent_race_real_connections():
    """Real concurrency: each thread opens its OWN psycopg2 connection
    (own Postgres backend process/transaction) — this is what the
    in-process Python model in bridge-runtime/round_lineage.py cannot
    prove (single-process mutex only). Final state must be exactly 3,
    regardless of thread interleaving or statement execution order,
    because the atomicity comes from the single UPDATE/INSERT
    statement itself, not from any Python-side lock."""
    lp = f"LP-PG-RACE-{uuid.uuid4()}"
    setup_conn = get_connection()
    try:
        truncate_bridge_tables(setup_conn)
    finally:
        setup_conn.close()

    attempts = [1, 2, 3, 1, 2, 3, 4, 4, 2]  # includes stale + over-limit, like the algo-level test
    results = []
    results_lock = threading.Lock()

    def worker(n):
        conn = get_connection()
        try:
            r = advance_round(conn, lp, n)
            with results_lock:
                results.append(r)
        finally:
            conn.close()

    threads = [threading.Thread(target=worker, args=(n,)) for n in attempts]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    verify_conn = get_connection()
    try:
        final = current_round(verify_conn, lp)
    finally:
        verify_conn.close()

    assert final == 3
    assert final <= 3
    successes = [r for r in results if r is not None]
    assert len(successes) >= 1  # at least the winning monotonic path succeeded


def test_pg_no_reset_via_different_dimension():
    """agent_id/provider/branch/workflow are not columns on
    bridge.round_lineage at all (see 015_bridge_runtime_schema.sql) —
    the table's ONLY key is logical_problem_id. This test proves that
    fact structurally: there is no column to even attempt a reset
    through."""
    conn = get_connection()
    try:
        truncate_bridge_tables(conn)
        with conn.cursor() as cur:
            cur.execute(
                "SELECT column_name FROM information_schema.columns "
                "WHERE table_schema='bridge' AND table_name='round_lineage'"
            )
            columns = {row[0] for row in cur.fetchall()}
        assert columns == {"logical_problem_id", "highest_round", "updated_at"}
        assert "agent_id" not in columns
        assert "branch" not in columns
        assert "provider" not in columns
        assert "conversation_id" not in columns
        assert "workflow" not in columns
    finally:
        conn.close()
