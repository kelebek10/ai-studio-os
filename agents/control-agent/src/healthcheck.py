import os

import psycopg


with psycopg.connect(
    host=os.getenv("PG_HOST", "peyzaj_postgres"),
    port=int(os.getenv("PG_PORT", "5432")),
    dbname=os.getenv("PG_DB", "peyzaj_db"),
    user=os.environ["PG_USER"],
    password=os.environ["PG_PASSWORD"],
    connect_timeout=5,
) as conn:
    with conn.cursor() as cur:
        cur.execute("SELECT 1")
        if cur.fetchone()[0] != 1:
            raise SystemExit(1)

print("HEALTH=PASS")
