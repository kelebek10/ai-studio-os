"""
COMM-BRIDGE-IMPLEMENT-05 — P1-2 REAL PostgreSQL integration tests.

STATUS: WRITTEN, NOT EXECUTED — same caveat as test_round_lineage_pg.py.
Do not cite any result here as PASS without an actual pytest run
against a real Postgres 16 instance producing the evidence (AC-01/02).

Exercises the real UNIQUE(idempotency_key) constraint on
bridge.result from 015_bridge_runtime_schema.sql, where
idempotency_key = logical_problem_id || ':' || artifact_digest per
governance/BRIDGE-RUNTIME-V1-PREREQUISITES-v1.0.md section 5 — the
literal contract, not a reimplementation (AC-05).

Run with:
    DATABASE_URL=postgresql://bridge_test:bridge_test@localhost:55432/paiforge_bridge_test \
      pytest tests/bridge-runtime/postgres_integration/test_replay_consumption_pg.py -v
"""
from __future__ import annotations
import os
import sys
import threading
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pg_conn import get_connection, truncate_bridge_tables


def _insert_task(conn, task_id, logical_problem_id, correlation_id):
    """bridge.result.task_id has a FK to bridge.task — a real task row
    must exist first, exactly as the schema requires (no shortcut
    around the FK constraint, per AC-05)."""
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO bridge.task (
                task_id, correlation_id, logical_problem_id, assigned_agent,
                task_type, scope, branch, source_commit, policy_version,
                permission_version, round_number, state
            ) VALUES (%s, %s, %s, 'AGENT-CLAUDE-001', 'IMPLEMENTATION',
                      '[]'::jsonb, 'feature/comm-bridge-runtime-v1',
                      '921f37d49180052af6ed9b41b190822cc4ffd866', 'v1.0', 'v1.0',
                      1, 'RESULT_SUBMITTED')
            ON CONFLICT (task_id) DO NOTHING
            """,
            (task_id, correlation_id, logical_problem_id),
        )
    conn.commit()


def submit_result(conn, task_id, logical_problem_id, correlation_id, artifact_digest):
    idempotency_key = f"{logical_problem_id}:{artifact_digest}"
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO bridge.result (
                task_id, correlation_id, logical_problem_id, agent_id,
                producer_status, source_commit, artifact_digest, idempotency_key,
                changed_files, tests, evidence_refs, risks, gaps,
                recommended_next_action, human_action_required
            ) VALUES (%s, %s, %s, 'AGENT-CLAUDE-001', 'SUBMITTED',
                      '921f37d49180052af6ed9b41b190822cc4ffd866', %s, %s,
                      '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, '[]'::jsonb,
                      NULL, false)
            """,
            (task_id, correlation_id, logical_problem_id, artifact_digest, idempotency_key),
        )
    conn.commit()


def test_pg_first_submission_accepted():
    conn = get_connection()
    try:
        truncate_bridge_tables(conn)
        lp, digest = f"LP-{uuid.uuid4()}", "deadbeef"
        _insert_task(conn, "T-1", lp, "C-1")
        submit_result(conn, "T-1", lp, "C-1", digest)
        with conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM bridge.result WHERE logical_problem_id=%s", (lp,))
            assert cur.fetchone()[0] == 1
    finally:
        conn.close()


def test_pg_different_task_id_same_logical_result_is_replay():
    """The real UNIQUE(idempotency_key) constraint, where
    idempotency_key excludes task_id, must reject this at the DB
    layer — not merely at the application layer."""
    conn = get_connection()
    try:
        truncate_bridge_tables(conn)
        lp, digest = f"LP-{uuid.uuid4()}", "deadbeef"
        _insert_task(conn, "T-1", lp, "C-1")
        _insert_task(conn, "T-2-DIFFERENT", lp, "C-2-DIFFERENT")
        submit_result(conn, "T-1", lp, "C-1", digest)

        raised = False
        try:
            submit_result(conn, "T-2-DIFFERENT", lp, "C-2-DIFFERENT", digest)
        except Exception as exc:
            conn.rollback()
            raised = True
            assert "idempotency_key" in str(exc) or "unique" in str(exc).lower()
        assert raised, "UNIQUE(idempotency_key) did not reject a same-logical-result replay under a different task_id"
    finally:
        conn.close()


def test_pg_different_logical_problem_accepted():
    conn = get_connection()
    try:
        truncate_bridge_tables(conn)
        digest = "deadbeef"
        lp1, lp2 = f"LP-{uuid.uuid4()}", f"LP-{uuid.uuid4()}"
        _insert_task(conn, "T-1", lp1, "C-1")
        _insert_task(conn, "T-3", lp2, "C-3")
        submit_result(conn, "T-1", lp1, "C-1", digest)
        submit_result(conn, "T-3", lp2, "C-3", digest)  # same digest, different logical_problem_id — OK
        with conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM bridge.result WHERE artifact_digest=%s", (digest,))
            assert cur.fetchone()[0] == 2
    finally:
        conn.close()


def test_pg_concurrent_duplicate_submission_only_one_wins():
    """Real concurrency: N threads, N separate psycopg2 connections,
    all racing to INSERT the same idempotency_key. Postgres's own
    UNIQUE constraint (not Python) must ensure exactly one commits."""
    lp, digest = f"LP-RACE-{uuid.uuid4()}", "digest-race"
    setup_conn = get_connection()
    try:
        truncate_bridge_tables(setup_conn)
        for i in range(12):
            _insert_task(setup_conn, f"T-race-{i}", lp, f"C-race-{i}")
    finally:
        setup_conn.close()

    accepted = []
    rejected = []
    lock = threading.Lock()

    def worker(i):
        conn = get_connection()
        try:
            submit_result(conn, f"T-race-{i}", lp, f"C-race-{i}", digest)
            with lock:
                accepted.append(i)
        except Exception:
            conn.rollback()
            with lock:
                rejected.append(i)
        finally:
            conn.close()

    threads = [threading.Thread(target=worker, args=(i,)) for i in range(12)]
    for t in threads:
        t.start()
    for t in threads:
        t.join()

    assert len(accepted) == 1, f"expected exactly 1 winner, got {len(accepted)}: {accepted}"
    assert len(rejected) == 11


def test_pg_transactional_consumption_only_after_commit():
    """A submission inside an open, uncommitted transaction must not
    be visible/consumed by another connection — proves the 'consumed
    only after INSERT commits' half of the P1-2 contract
    (BRIDGE-RUNTIME-001 section 5, point 2)."""
    lp, digest = f"LP-{uuid.uuid4()}", "deadbeef-txn"
    setup_conn = get_connection()
    try:
        truncate_bridge_tables(setup_conn)
        _insert_task(setup_conn, "T-txn", lp, "C-txn")
    finally:
        setup_conn.close()

    writer_conn = get_connection()
    reader_conn = get_connection()
    try:
        writer_conn.autocommit = False
        idempotency_key = f"{lp}:{digest}"
        with writer_conn.cursor() as cur:
            cur.execute(
                """
                INSERT INTO bridge.result (
                    task_id, correlation_id, logical_problem_id, agent_id,
                    producer_status, source_commit, artifact_digest, idempotency_key,
                    changed_files, tests, evidence_refs, risks, gaps,
                    recommended_next_action, human_action_required
                ) VALUES ('T-txn', 'C-txn', %s, 'AGENT-CLAUDE-001', 'SUBMITTED',
                          '921f37d49180052af6ed9b41b190822cc4ffd866', %s, %s,
                          '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, '[]'::jsonb, '[]'::jsonb,
                          NULL, false)
                """,
                (lp, digest, idempotency_key),
            )
        # NOT committed yet — reader_conn must not see it
        with reader_conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM bridge.result WHERE idempotency_key=%s", (idempotency_key,))
            assert cur.fetchone()[0] == 0, "uncommitted result was visible to another connection"

        writer_conn.commit()

        with reader_conn.cursor() as cur:
            cur.execute("SELECT count(*) FROM bridge.result WHERE idempotency_key=%s", (idempotency_key,))
            assert cur.fetchone()[0] == 1, "committed result was not visible after commit"
    finally:
        writer_conn.close()
        reader_conn.close()
