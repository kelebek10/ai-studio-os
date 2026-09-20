import os
from datetime import datetime, timezone
import hashlib
import json
import uuid

import psycopg

PG_HOST = os.getenv("PG_HOST", "peyzaj_postgres")
PG_PORT = int(os.getenv("PG_PORT", "5432"))
PG_DB = os.getenv("PG_DB", "peyzaj_db")
PG_USER = os.environ["PG_USER"]
PG_PASSWORD = os.environ["PG_PASSWORD"]


def stage1_observe(
    task_state="READY",
    evidence_state="VALID",
    authority_state="VALID",
):
    blockers = []

    if evidence_state in (None, "MISSING"):
        blockers.append("MISSING_EVIDENCE")
    if task_state in (None, "UNKNOWN") or evidence_state == "UNKNOWN":
        blockers.append("UNKNOWN_STATE")
    if authority_state != "VALID":
        blockers.append("AUTHORITY_INVALID")

    if "MISSING_EVIDENCE" in blockers or "AUTHORITY_INVALID" in blockers:
        overall_status = "BLOCKED"
    elif "UNKNOWN_STATE" in blockers:
        overall_status = "UNKNOWN"
    else:
        overall_status = "PASS"

    observation = {
        "observation_id": str(uuid.uuid4()),
        "timestamp": datetime.now(timezone.utc).isoformat(),
        "task_id": "M15-STAGE1",
        "task_state": task_state,
        "evidence_state": evidence_state,
        "authority_state": authority_state,
        "runtime_state": "HEALTHY",
        "blockers": blockers,
        "overall_status": overall_status,
        "source": "control-agent",
    }
    return observation


def observation_fingerprint(observation):
    stable = {
        key: observation[key]
        for key in (
            "task_id",
            "task_state",
            "evidence_state",
            "authority_state",
            "runtime_state",
            "blockers",
            "overall_status",
            "source",
        )
    }
    payload = json.dumps(stable, sort_keys=True, separators=(",", ":")).encode()
    return hashlib.sha256(payload).hexdigest()


def real_observation():
    with psycopg.connect(
        host=PG_HOST,
        port=PG_PORT,
        dbname=PG_DB,
        user=PG_USER,
        password=PG_PASSWORD,
        connect_timeout=5,
    ) as conn:
        with conn.cursor() as cur:
            cur.execute("""
                SELECT
                    current_database(),
                    current_user,
                    current_schema(),
                    has_database_privilege(current_user, current_database(), 'CREATE'),
                    has_database_privilege(current_user, current_database(), 'TEMP'),
                    has_schema_privilege(current_user, 'public', 'CREATE')
            """)
            db, user, schema, db_create, db_temp, schema_create = cur.fetchone()
            cur.execute("""
                SELECT count(*)
                FROM information_schema.tables
                WHERE table_schema NOT IN ('pg_catalog', 'information_schema')
            """)
            table_count = cur.fetchone()[0]

    print("CONTROL AGENT: OBSERVATION PASS")
    print(f"DB={db}")
    print(f"USER={user}")
    print(f"SCHEMA={schema}")
    print(f"APPLICATION_TABLES={table_count}")
    print(f"DATABASE_CREATE={db_create}")
    print(f"DATABASE_TEMP={db_temp}")
    print(f"SCHEMA_CREATE={schema_create}")
    print("MODE=READ_ONLY")


if __name__ == "__main__":
    real_observation()
