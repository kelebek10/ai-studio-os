"""
COMM-BRIDGE-IMPLEMENT-05 — connection helper for the real-Postgres
integration test harness.

STATUS: WRITTEN, NOT EXECUTED. Requires `psycopg2` and a reachable
Postgres 16 instance with migrations/nonprod/001..015 applied (see
infra/nonprod/docker-compose.postgres.yml). Claude's working
environment has neither `psycopg2` installed nor network/DB access
(confirmed this task) — this module has never been imported
successfully in this environment. It exists so whoever has real
access can run `pytest tests/bridge-runtime/postgres_integration/`
immediately, with no additional harness code to write.
"""
from __future__ import annotations
import os


def get_connection():
    """Returns a new psycopg2 connection using DATABASE_URL from the
    environment. Raises RuntimeError with a clear message if
    DATABASE_URL is unset or psycopg2 is unavailable — this harness
    fails loudly rather than silently falling back to any in-memory
    or mock substitute (AC-04: no mock DB, no SQLite substitute)."""
    database_url = os.environ.get("DATABASE_URL")
    if not database_url:
        raise RuntimeError(
            "DATABASE_URL is not set. This test harness requires a real "
            "Postgres 16 instance (see infra/nonprod/docker-compose.postgres.yml) "
            "with migrations 001..015 applied. There is no mock/fallback path — "
            "per COMM-BRIDGE-IMPLEMENT-05 AC-04, a missing real DB means these "
            "tests must not run, not run against a substitute."
        )
    try:
        import psycopg2
    except ImportError as exc:
        raise RuntimeError(
            "psycopg2 is not installed. See "
            "tests/bridge-runtime/postgres_integration/requirements.txt. "
            "No fallback DB driver or mock is used (AC-04)."
        ) from exc
    return psycopg2.connect(database_url)


def truncate_bridge_tables(conn) -> None:
    """Test isolation helper: clears bridge.* tables between test runs.
    Never touches governance.* or core.* tables from earlier
    migrations (AC-10: must not disturb existing IMPLEMENT-03/04
    schema/behavior outside the bridge schema this task owns)."""
    with conn.cursor() as cur:
        cur.execute(
            "TRUNCATE TABLE bridge.audit_event, bridge.delegation, "
            "bridge.round_lineage, bridge.result, bridge.ack, bridge.task "
            "RESTART IDENTITY CASCADE;"
        )
    conn.commit()
