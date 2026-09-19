"""
COMM-BRIDGE-IMPLEMENT-05 — P1-3 REAL PostgreSQL DB-layer containment
tests.

STATUS: WRITTEN, NOT EXECUTED — same caveat as the other files in this
directory. Do not cite any result here as PASS without an actual
pytest run against a real Postgres 16 instance (AC-01/02).

Exercises the REAL `delegation_scope_subset` CHECK constraint from
015_bridge_runtime_schema.sql:

    CONSTRAINT delegation_scope_subset CHECK (
      scope <@ (SELECT scope FROM bridge.task WHERE task_id = parent_task_id)
    )

This is the DB-layer half of the P1-3 defense-in-depth pair; the
application-layer half is bridge-runtime/delegation_scope.py
(COMM-BRIDGE-IMPLEMENT-04, 9/9 algorithm-level PASS, unchanged by this
file). Both must independently reject the same violations for the
defense-in-depth claim to hold — this file tests the DB half only.

SCOPE TOKEN VOCABULARY GAP (see governance/
BRIDGE-RUNTIME-V1-POSTGRES-READINESS-v1.0.md section 4 for the full
finding): governance/AGENT-PERMISSION-MODEL-v1.0.md does not define a
scope-token vocabulary. The token strings used below
("read:governance", "write:evidence", etc.) are the SAME placeholder
set already used in bridge-runtime/delegation_scope.py's
KNOWN_SCOPE_TOKENS (COMM-BRIDGE-IMPLEMENT-04) — reused here for
consistency with the application-layer tests, NOT presented as a
governance-sourced vocabulary. This is a known, reported gap, not
invented authority (AC-05).

Run with:
    DATABASE_URL=postgresql://bridge_test:bridge_test@localhost:55432/paiforge_bridge_test \
      pytest tests/bridge-runtime/postgres_integration/test_delegation_scope_pg.py -v
"""
from __future__ import annotations
import json
import os
import sys
import uuid

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from pg_conn import get_connection, truncate_bridge_tables


def _insert_parent_task(conn, task_id, logical_problem_id, scope: list[str]):
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO bridge.task (
                task_id, correlation_id, logical_problem_id, assigned_agent,
                task_type, scope, branch, source_commit, policy_version,
                permission_version, round_number, state
            ) VALUES (%s, 'C-PARENT', %s, 'AGENT-CLAUDE-001', 'IMPLEMENTATION',
                      %s::jsonb, 'feature/comm-bridge-runtime-v1',
                      '921f37d49180052af6ed9b41b190822cc4ffd866', 'v1.0', 'v1.0',
                      1, 'WORKING')
            """,
            (task_id, logical_problem_id, json.dumps(scope)),
        )
    conn.commit()


def _insert_delegation(conn, parent_task_id, logical_problem_id, scope: list[str]):
    with conn.cursor() as cur:
        cur.execute(
            """
            INSERT INTO bridge.delegation (
                parent_task_id, correlation_id, logical_problem_id,
                specialist_id, scope, status
            ) VALUES (%s, 'C-DELEGATE', %s, 'AGENT-SPECIALIST-001', %s::jsonb, 'CREATED')
            """,
            (parent_task_id, logical_problem_id, json.dumps(scope)),
        )
    conn.commit()


def test_pg_valid_subset_delegation_accepted():
    conn = get_connection()
    try:
        truncate_bridge_tables(conn)
        lp = f"LP-{uuid.uuid4()}"
        parent_task = f"T-PARENT-{uuid.uuid4()}"
        _insert_parent_task(conn, parent_task, lp, ["read:governance", "read:evidence"])
        _insert_delegation(conn, parent_task, lp, ["read:evidence"])  # subset — must succeed
        with conn.cursor() as cur:
            cur.execute(
                "SELECT count(*) FROM bridge.delegation WHERE parent_task_id=%s", (parent_task,)
            )
            assert cur.fetchone()[0] == 1
    finally:
        conn.close()


def test_pg_scope_expansion_rejected_by_db_constraint():
    """The application layer (delegation_scope.py) would already
    reject this — this test proves the DB CHECK constraint ALSO
    rejects it independently, i.e. that the defense-in-depth pair
    actually has two working layers, not one working layer and one
    that silently never fires."""
    conn = get_connection()
    try:
        truncate_bridge_tables(conn)
        lp = f"LP-{uuid.uuid4()}"
        parent_task = f"T-PARENT-{uuid.uuid4()}"
        _insert_parent_task(conn, parent_task, lp, ["read:evidence"])
        raised = False
        try:
            # child requests write:task_result, which parent does NOT have
            _insert_delegation(conn, parent_task, lp, ["read:evidence", "write:task_result"])
        except Exception as exc:
            conn.rollback()
            raised = True
            assert "delegation_scope_subset" in str(exc) or "check" in str(exc).lower()
        assert raised, "delegation_scope_subset CHECK constraint did not reject scope expansion"
    finally:
        conn.close()


def test_pg_empty_child_scope_is_trivially_valid_subset():
    """Empty set is a subset of any set — a delegation requesting no
    additional scope must be permitted by the constraint (sanity check
    that the constraint isn't accidentally rejecting everything)."""
    conn = get_connection()
    try:
        truncate_bridge_tables(conn)
        lp = f"LP-{uuid.uuid4()}"
        parent_task = f"T-PARENT-{uuid.uuid4()}"
        _insert_parent_task(conn, parent_task, lp, ["read:evidence"])
        _insert_delegation(conn, parent_task, lp, [])
        with conn.cursor() as cur:
            cur.execute(
                "SELECT count(*) FROM bridge.delegation WHERE parent_task_id=%s", (parent_task,)
            )
            assert cur.fetchone()[0] == 1
    finally:
        conn.close()


def test_pg_nonexistent_parent_task_rejected_by_fk_not_by_scope():
    """A delegation referencing a parent_task_id that doesn't exist
    must fail on the FK constraint (bridge.delegation.parent_task_id
    REFERENCES bridge.task), independent of scope — confirms lineage
    integrity (parent_task_id) is enforced at the DB layer too, not
    just logical_problem_id/correlation_id at the application layer."""
    conn = get_connection()
    try:
        truncate_bridge_tables(conn)
        raised = False
        try:
            _insert_delegation(conn, "T-DOES-NOT-EXIST", "LP-X", [])
        except Exception as exc:
            conn.rollback()
            raised = True
            assert "foreign key" in str(exc).lower() or "violat" in str(exc).lower()
        assert raised, "FK constraint on bridge.delegation.parent_task_id did not reject a nonexistent parent"
    finally:
        conn.close()
