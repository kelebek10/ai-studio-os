# Bridge Runtime v1 — real PostgreSQL readiness (COMM-BRIDGE-IMPLEMENT-05)

STATUS: This whole directory's contents have been **written but never
executed**. Claude's working environment has no Docker daemon, no
network egress, and no psycopg2/Postgres connector (confirmed this
task — see `governance/BRIDGE-RUNTIME-V1-POSTGRES-READINESS-v1.0.md`
section 2 for the exact evidence: `apt-get install postgresql` →
`403 Forbidden` from the egress proxy; `tool_search` → zero DB
connectors). Nothing here has produced a single real Postgres query
result. It exists so a human or CI with real Docker + Postgres access
can run it immediately with no further harness-writing.

## What's here

- `infra/nonprod/docker-compose.postgres.yml` — disposable Postgres 16,
  port 55432, named volume (survives `restart`, destroyed only by
  `down -v`).
- `tests/bridge-runtime/postgres_integration/` — real `psycopg2`-based
  pytest suite targeting the exact schema in
  `migrations/nonprod/015_bridge_runtime_schema.sql` and the exact
  contract SQL in `governance/BRIDGE-RUNTIME-V1-PREREQUISITES-v1.0.md`
  sections 4–6 (not a reimplementation — the literal statements).
- `tests/bridge-runtime/postgres_integration/restart_test_write_phase.py`
  / `restart_test_verify_phase.py` — the two-phase restart-persistence
  procedure (see below).

## How to run it (by a party with real access)

```bash
docker compose -f infra/nonprod/docker-compose.postgres.yml up -d

# Apply migrations in order — 015 depends on governance.migration_ledger
# and governance.reject_mutation() defined starting in 001:
export DATABASE_URL=postgresql://bridge_test:bridge_test@localhost:55432/paiforge_bridge_test
for f in migrations/nonprod/0*.sql; do
  echo "applying $f"
  psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f "$f"
done

pip install -r tests/bridge-runtime/postgres_integration/requirements.txt

pytest tests/bridge-runtime/postgres_integration/ -v
```

## Restart-persistence procedure (P1-1/P1-2/P1-3 "restart sonrası
## state/replay/delegation persistence" requirement)

A single pytest process cannot restart its own database mid-run, so
this is a manual/CI two-phase procedure, not an automated test:

```bash
# Phase 1 — write known state
python tests/bridge-runtime/postgres_integration/restart_test_write_phase.py

# Restart WITHOUT deleting the volume
docker compose -f infra/nonprod/docker-compose.postgres.yml restart postgres

# Phase 2 — verify the state survived AND is still enforced
python tests/bridge-runtime/postgres_integration/restart_test_verify_phase.py
echo "exit code: $?"
```

Phase 2 checks both persistence (rows still exist, unchanged) and
continued enforcement (round 4 still denied, replay still denied,
scope-expansion CHECK still fires) — a row merely existing after
restart is not sufficient evidence; the constraints must still be
live.

**Never** run `docker compose ... down -v` between phase 1 and phase 2
— `-v` deletes the named volume this test exists to prove survives a
restart.

## What this does NOT prove

- Multi-host / multi-instance Postgres replication or failover.
- Crash recovery from an unclean shutdown (`docker compose restart`
  is a clean stop+start, not a crash simulation).
- Any behavior under production load or production data volume — this
  is nonprod-only, disposable, per
  `governance/BRIDGE-RUNTIME-V1-PREREQUISITES-v1.0.md` section 9.

## Scope token vocabulary gap (P1-3)

`bridge-runtime/delegation_scope.py`'s `KNOWN_SCOPE_TOKENS` (from
COMM-BRIDGE-IMPLEMENT-04) and this directory's
`test_delegation_scope_pg.py` both use the same placeholder token
strings. `governance/AGENT-PERMISSION-MODEL-v1.0.md` was read in full
for COMM-BRIDGE-IMPLEMENT-05 and confirmed to define **no scope-token
vocabulary at all** — it defines round/conflict permission dimensions
only. Per `BRIDGE-RUNTIME-V1-PREREQUISITES-v1.0.md` section 6, this is
recorded as a **prerequisite gap**, not invented here. Whoever runs
this suite should be aware the token strings are illustrative
placeholders pending a real governance-defined vocabulary, not a
verified permission set.
