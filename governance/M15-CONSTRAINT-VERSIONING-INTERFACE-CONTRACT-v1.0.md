# M15 Constraint Versioning Interface Contract v1.0

**Status:** CONTROLLED DESIGN INPUT  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`  
**Dependency:** M14 Approval Authority PASS  
**Production status:** BLOCKED

## 1. Purpose

Define the minimum canonical PostgreSQL interface required by M15 Constraint Versioning tests. This contract is non-production design input; it does not authorize production migration or execution.

## 2. Canonical objects

### 2.1 Version table

Canonical table name:

`governance.constraint_versions`

Required columns:

- `version` — unique, immutable logical constraint version identifier.
- `scope` — canonical constraint scope identifier.
- `idempotency_key` — unique key for one logical state transition request.
- `provenance_hash` — integrity reference for the evidence/provenance package.
- `created_at` — server-generated creation timestamp.
- `created_by` — provenance principal/reference; not an approval authority field.
- `status` — version lifecycle state.

Required invariants:

- `version`, `scope`, `idempotency_key`, `provenance_hash`, `created_at`, `created_by`, and `status` are NOT NULL.
- `(scope, idempotency_key)` is UNIQUE.
- A version is never silently overwritten.
- Historical rows remain auditable.

## 3. Canonical apply interface

Canonical function name:

`governance.apply_constraint_version(p_version text, p_scope text, p_idempotency_key text, p_provenance_hash text, p_actor text)`

The function must:

1. validate that the requested version exists and is applicable to the supplied scope;
2. reject unknown/invalid versions;
3. reject unauthorized scope substitution;
4. enforce idempotency atomically;
5. record provenance;
6. preserve historical state;
7. fail closed on NULL/unknown authority inputs;
8. never create or infer a human governance approval;
9. remain compatible with the M14 approval boundary.

## 4. Authority boundary

M15 is not an approval authority.

The function may apply an already-authorized constraint-version transition only within its defined task/data boundary. It must not:

- create a `HUMAN_APPROVER` approval;
- update authoritative governance approval state directly;
- modify `governance/CURRENT-STATE.md`;
- treat AI/workflow metadata as human authorization;
- bypass or replace the M14 approval function.

## 5. Version transition model

Minimum supported transition:

`v1 -> v2`

Rules:

- transition must be explicit;
- source and target versions must be recorded;
- unsupported transitions fail closed;
- repeated application with the same idempotency key is a no-op or deterministic existing-result return;
- a different scope/version using an existing idempotency key is rejected.

## 6. Concurrency

Concurrent requests for the same `(scope, idempotency_key)` must resolve atomically. Exactly one logical transition may be committed. A conflicting request must return the existing deterministic result or a controlled rejection; it must never create duplicate state.

## 7. Rollback

Rollback is an explicit version transition, not destructive deletion. Historical provenance remains intact. Failed transactions must leave no partial version state.

## 8. Provenance

Every accepted transition requires a non-empty `provenance_hash`. Provenance identifies the evidence package used for the transition. Provenance is evidence, not authority.

## 9. Fail-closed rules

The implementation is BLOCKED when any of the following is UNKNOWN or missing:

- canonical version;
- scope;
- idempotency key;
- provenance hash;
- authority context;
- applicable transition;
- transaction result.

## 10. M15 test mapping

- T04 — current version readable
- T05 — invalid version rejected
- T06 — retry/idempotency
- T07 — scope substitution rejected
- T08 — provenance queryable and mandatory
- T09 — rollback/no partial state
- T10 — schema-level mandatory provenance/scope

## 11. Acceptance boundary

This contract authorizes only non-production implementation and testing of M15. It does not authorize production SQL, production migration, production data import, infrastructure mutation, or governance baseline modification.

**Next controlled artifact:** non-production migration implementing this contract, followed by T01–T10 execution and independent review.