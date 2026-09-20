# PAI-FORGE — Bridge Runtime v1 Real-PostgreSQL Readiness Report

Document ID: BRIDGE-RUNTIME-003
Version: 1.0
Status: NON-PROD INFRASTRUCTURE + TEST PREPARATION ONLY — NO REAL
POSTGRES EVIDENCE PRODUCED
Branch: feature/comm-bridge-runtime-v1
Owner: Human Project Owner
Parent: BRIDGE-RUNTIME-001, BRIDGE-RUNTIME-002 (P0/P1 closure),
BRIDGE-TGA-CAW-001
Author: AGENT-CLAUDE-001 (per COMM-BRIDGE-IMPLEMENT-05)
Reviewer: AGENT-GPT-001 (independent verification required)

## 0. Single objective of this task, and what "done" means here

COMM-BRIDGE-IMPLEMENT-05's single objective was: prepare the non-prod
infrastructure and test readiness needed to move to REAL PostgreSQL
runtime verification for P1-1/P1-2/P1-3. It did **not** ask for a
runtime PASS — AC-01 through AC-03 explicitly forbid claiming one
without real evidence. "Done" for this task means: the infrastructure
and test artifacts exist, are believed correct against the real
schema/contract, and are ready for someone with real Postgres access
to run — not that they have been run.

## 1. KONTROL — environment capability check (repeated, this task)

Performed fresh for this task, not assumed from prior tasks:

| Check | Result |
|---|---|
| `tool_search` for postgres/database/sql/webhook connectors | Zero results |
| `which psql postgres pg_ctl initdb` | Not found (exit 127) |
| `python3 -c "import psycopg2"` | `ModuleNotFoundError` |
| `curl https://example.com` | `403` (egress proxy blocks all network) |
| `apt-get install -y postgresql` | `403 Forbidden` on every package fetch — confirmed no path to install locally either |
| `mcp__GitHub__get_me` (repeated from IMPLEMENT-04) | Still only public profile fields, no scope enumeration |

**Conclusion: no real PostgreSQL access exists in this environment,
confirmed by four independent methods (connector search, binary
search, module import, network fetch), not assumed.** This is
unchanged from every prior Bridge Runtime task since
COMM-BRIDGE-IMPLEMENT-02, now re-verified rather than carried forward
by assertion.

## 2. DOĞRULAMA — prior outputs and governance state reviewed

Before writing anything, the following were re-read in full for this
task:
- `migrations/nonprod/015_bridge_runtime_schema.sql` (commit
  `921f37d4...` state) — confirmed the real schema: `bridge.task`,
  `bridge.ack`, `bridge.result` (UNIQUE idempotency_key), `bridge.
  round_lineage` (CHECK highest_round <= 3, UPDATE-only-no-DELETE
  trigger), `bridge.delegation` (delegation_scope_subset CHECK using
  `<@`), `bridge.audit_event` (append-only trigger).
- `governance/BRIDGE-RUNTIME-V1-PREREQUISITES-v1.0.md` — confirmed the
  exact contract SQL for atomic round advance (section 4) and the
  idempotency key definition (section 5).
- `governance/AGENT-PERMISSION-MODEL-v1.0.md` — read in full. **Finding:
  this document defines round/conflict permission dimensions (3-round
  hard stop, counter-reset prohibition, fail-closed conditions) but
  contains NO scope-token vocabulary** (no list resembling
  `read:governance`, `write:evidence`, etc.). This confirms, rather
  than resolves, the gap `BRIDGE-RUNTIME-V1-PREREQUISITES-v1.0.md`
  section 6 flagged as possible: *"If AGENT-PERMISSION-MODEL-v1.0.md
  does not yet define a token vocabulary suitable for this, that is a
  prerequisite gap, not something this document invents by itself."*
  Per that instruction and this task's own rule ("Uyuşmazlık varsa
  token uydurma; GAP olarak raporla"), no token vocabulary was
  invented. `bridge-runtime/delegation_scope.py`'s
  `KNOWN_SCOPE_TOKENS` (COMM-BRIDGE-IMPLEMENT-04) remains an
  unchanged placeholder — **not edited by this task** — and the new
  `test_delegation_scope_pg.py` reuses the same placeholder strings
  for consistency, explicitly labeled as such.
- `migrations/nonprod/` directory listing — confirmed `015` depends on
  `governance.migration_ledger` / `governance.reject_mutation()`
  originating in `001_paiforge_v13_foundation.sql`, meaning a real
  readiness run needs `001` through `015` applied in order, not `015`
  alone. Documented in the new README.

## 3. UYGULAMA — what was built

All under `feature/comm-bridge-runtime-v1`, non-prod scope only:

| File | Purpose |
|---|---|
| `infra/nonprod/docker-compose.postgres.yml` | Disposable Postgres 16, port 55432, named volume for restart testing |
| `infra/nonprod/README-bridge-postgres-readiness.md` | Setup, run, and restart-test procedure |
| `tests/bridge-runtime/postgres_integration/requirements.txt` | `psycopg2-binary`, `pytest` |
| `tests/bridge-runtime/postgres_integration/pg_conn.py` | Connection helper — **fails closed** (raises `RuntimeError`) if `DATABASE_URL` is unset or `psycopg2` is missing; no mock/SQLite fallback exists anywhere in this path (AC-04) |
| `tests/bridge-runtime/postgres_integration/test_round_lineage_pg.py` | P1-1: monotonic advance, stale-transition zero-rows, round-4 denial via the literal contract SQL, direct-insert CHECK-constraint rejection, real multi-connection concurrent race, column-level proof that no other-dimension reset path exists |
| `tests/bridge-runtime/postgres_integration/test_replay_consumption_pg.py` | P1-2: first-submission accept, different-task-id-same-result replay rejection via the real UNIQUE constraint, different-logical-problem accepted, real multi-connection concurrent duplicate race, transactional visibility (uncommitted insert invisible to another connection) |
| `tests/bridge-runtime/postgres_integration/test_delegation_scope_pg.py` | P1-3: valid subset accepted, scope expansion rejected by the real `delegation_scope_subset` CHECK (`<@` containment), empty-scope sanity check, FK-layer parent-task integrity |
| `tests/bridge-runtime/postgres_integration/restart_test_write_phase.py` + `restart_test_verify_phase.py` | Two-phase restart-persistence procedure covering round lineage, replay, and delegation state, verifying both persistence AND continued enforcement post-restart |

**Everything above targets the schema and contract SQL already
committed in COMM-BRIDGE-IMPLEMENT-03 (`015_bridge_runtime_schema.sql`,
`BRIDGE-RUNTIME-V1-PREREQUISITES-v1.0.md`) verbatim.** No new table,
no new constraint, no new idempotency-key definition, no reinterpreted
contract was introduced (AC-05). No new framework or architectural
layer was added — this is docker-compose plus a pytest suite using
the same `psycopg2` pattern the repo's SQL migrations already assume
a real DB party would use (AC-08).

## 4. TEST — what was actually executed, and what was not

**Actually executed in this environment (real, verifiable):**
- `python3 -m py_compile` on all six new Python files — all pass
  (syntax-valid).
- `pg_conn.get_connection()` called with no `DATABASE_URL` set —
  confirmed it raises `RuntimeError` with an explicit message, rather
  than silently connecting to nothing or falling back to any mock
  (AC-04 self-check, real output captured).
- The full existing 51/51 algorithm-level suite from
  COMM-BRIDGE-IMPLEMENT-03/04
  (`authority_gate`/`round_lineage`/`replay_consumption`/
  `delegation_scope`/`trigger_auth`) was re-run unchanged and still
  passes 51/51 — confirms this task did not disturb prior behavior
  (AC-10).

**NOT executed, and not claimed as executed:**
- None of `test_round_lineage_pg.py`, `test_replay_consumption_pg.py`,
  `test_delegation_scope_pg.py`, or the restart-test scripts have run
  against a real Postgres connection. **Zero SQL statements from these
  files have been sent to any database.** This is stated plainly per
  AC-01/AC-02 — no result from this task is labeled PASS for any
  P1-1/P1-2/P1-3 runtime criterion.

## 5. TEKRAR KONTROL — final capability confirmation

Repeating the section 1 checks after all files were written produces
the identical result: no Docker, no network, no DB connector, no
`psycopg2`. Nothing changed mid-task that would allow execution. This
is the controlled stopping point instructed by this task
("gerçek altyapı erişimi yoksa orada kontrollü şekilde DUR").

## 6. Status table (PASS / FAIL / BLOCKED / UNVERIFIED only)

| Item | Status |
|---|---|
| Non-prod Postgres 16 infra definition | **UNVERIFIED** (written, not run) |
| P1-1 real-Postgres round lineage (atomic advance, round-4 denial, concurrency, reset-prevention) | **BLOCKED** (no real Postgres access) |
| P1-2 real-Postgres replay/idempotency, transactional consumption | **BLOCKED** |
| P1-3 real-Postgres delegation scope DB-layer containment | **BLOCKED** |
| P1-3 scope-token vocabulary reconciliation against `AGENT-PERMISSION-MODEL-v1.0.md` | **CAPABILITY GAP** — vocabulary does not exist in governance yet; not invented |
| Restart persistence (round/replay/delegation) | **BLOCKED** (no real Postgres access to restart) |
| Test-harness syntax/import validity | **PASS** (`py_compile`, real, executed) |
| Fail-closed behavior of connection helper (no mock fallback) | **PASS** (real, executed, `RuntimeError` observed) |
| Existing IMPLEMENT-03/04 behavior undisturbed | **PASS** (51/51 re-run, unchanged) |

## 7. Risks

- The pytest files were written against the schema as read, but have
  never been executed — there may be a typo, a wrong column name, or
  an incorrect assumption about `psycopg2` error message text (used
  loosely in a few `assert "..." in str(exc)` checks) that only a real
  run will surface. These should be treated as a first draft requiring
  a real test run and possible minor correction, not a finished,
  proven suite.
- The `delegation_scope_subset` CHECK constraint re-evaluates a
  subquery (`SELECT scope FROM bridge.task WHERE task_id =
  parent_task_id`) on every insert/update to `bridge.delegation`; at
  scale this has a performance cost the original schema author should
  be aware of (not a correctness risk, a design note).
- The restart test's "clean restart" (`docker compose restart`) is not
  equivalent to an unclean crash; if crash-safety specifically matters
  for production sign-off later, a separate `kill -9`-style test would
  be needed — out of scope here and not attempted.

## 8. Remaining blockers (unchanged from IMPLEMENT-04, reconfirmed)

- No deployed webhook listener (P0-1 runtime, P0-2)
- No reachable Postgres from this environment (P1-1/P1-2/P1-3 runtime)
- No Bridge-held Claude API/Claude Code dispatch credential (P0-2)
- No specialist-agent runtime delegation mechanism (P1-4)
- No scope-token vocabulary in `AGENT-PERMISSION-MODEL-v1.0.md` (P1-3,
  newly confirmed this task — previously only hypothesized as a risk)
- GitHub token scope not fully enumerable from this environment (P1-5)

## 9. Recommended next action

1. A human or CI with Docker + network access runs
   `infra/nonprod/docker-compose.postgres.yml`, applies migrations
   001–015, and executes `pytest tests/bridge-runtime/postgres_integration/
   -v`, capturing the real output.
2. That same party runs the two-phase restart procedure and saves the
   `restart_test_verify_phase.py` console output as the restart-
   persistence evidence artifact.
3. Any test failures found on first real execution should be corrected
   against the real error, not worked around — these files are a
   first draft against a schema that itself has never been applied to
   a live database either.
4. Separately, the Human Project Owner should decide whether
   `AGENT-PERMISSION-MODEL-v1.0.md` needs a scope-token vocabulary
   section added — this task deliberately did not add one.

No item in this report is a real-runtime PASS. Implementer does not
self-certify this as final — GPT independent verification required.
