import os
import time

import psycopg

PG_HOST = os.getenv("PG_HOST", "peyzaj_postgres")
PG_PORT = int(os.getenv("PG_PORT", "5432"))
PG_DB = os.getenv("PG_DB", "peyzaj_db")
PG_USER = os.environ["PG_USER"]
PG_PASSWORD = os.environ["PG_PASSWORD"]


def check_database():
    with psycopg.connect(
        host=PG_HOST,
        port=PG_PORT,
        dbname=PG_DB,
        user=PG_USER,
        password=PG_PASSWORD,
        connect_timeout=5,
    ) as conn:
        with conn.cursor() as cur:
            cur.execute("SELECT 1")
            return cur.fetchone()[0] == 1


while True:
    try:
        if not check_database():
            raise RuntimeError("database health check failed")
        print("CONTROL AGENT: HEALTH PASS | MODE=READ_ONLY", flush=True)
        time.sleep(30)
    except Exception as exc:
        print(
            f"CONTROL AGENT: BLOCKED ({type(exc).__name__}): {exc}",
            flush=True,
        )
        raise SystemExit(1)
