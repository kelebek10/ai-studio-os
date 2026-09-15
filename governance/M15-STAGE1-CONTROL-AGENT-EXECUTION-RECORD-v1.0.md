# M15 Stage 1 — Control Agent Execution Record

**Status:** PASS
**Branch:** `phase-1-3-foundation`
**Execution date:** 2026-09-15
**Scope:** Controlled Stage 1 runtime validation

## Runtime Evidence

- Canonical image: `paiforge-control-agent:canonical-20260915`
- Image digest: `sha256:76a480d27506b6fb6c6dd0dccd3ed89e9ed9ff17ac846cedbd33f5e82ff2395a`
- Platform: `linux/arm64`
- Production PostgreSQL connectivity: PASS
- Runtime status after cutover: `running`
- Restart count: `0`
- Docker health: `healthy`
- Runtime mode: `READ_ONLY`

## Stage 1 Tests

| Test | Result | Evidence |
|---|---|---|
| O1 Real Observation | PASS | Real observation returned DB identity, privileges and `MODE=READ_ONLY` |
| O2 Missing Evidence | PASS | `overall_status=BLOCKED`, blocker `MISSING_EVIDENCE` |
| O3 Unknown State | PASS | `overall_status=UNKNOWN`, blocker `UNKNOWN_STATE` |
| O4 Mutation Denial | PASS | PostgreSQL denied `CREATE TABLE` with `InsufficientPrivilege` |
| O5 Repeatability | PASS | Two identical fingerprints: `a2fc7509e42b31d16a06ef86e4578568555c63e8b637bbf437ba6f04248f743b` |

## Credential / Runtime Hardening

- Production runner role: `paiforge_runner_ro`
- `LOGIN=true`, `SUPERUSER=false`, `CREATEDB=false`, `CREATEROLE=false`
- Schema `USAGE=true`, `CREATE=false`
- Database `CONNECT=true`, `CREATE=false`, `TEMP=false`
- Credential was rotated after accidental exposure during diagnosis.
- Secret values are not recorded in this repository.
- Legacy container was retained under `paiforge-control-agent-legacy-20260915` for rollback.

## Gate Decision

**M15 Stage 1 = PASS.**

This record proves the tested Control Agent runtime satisfies the Stage 1 observation, fail-closed, mutation-denial and repeatability controls. It does not authorize production migration or broader agent orchestration.

## Constraints

- Production migration remains blocked pending separate approval.
- Production SQL execution and data import remain blocked.
- Broader AI-agent orchestration remains subject to the existing governance gates.
