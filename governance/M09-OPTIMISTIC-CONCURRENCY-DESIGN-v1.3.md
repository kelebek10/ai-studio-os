# PAI-FORGE — M09 Optimistic Concurrency Design v1.3

**Status:** CONTROLLED DESIGN — NONPROD VALIDATION REQUIRED
**Branch:** `phase-1-3-foundation`

## Decision
M09-N05 requires a true Design Head / Compare-and-Set (CAS) boundary. Row locking on `change_request` alone is insufficient because two writers can validate against the same Design State without atomically claiming the authoritative head.

## Design Head
`governance.design_head` represents the single authoritative head per `design_id`:
- `design_id` UUID PRIMARY KEY
- `design_state_id` UUID NOT NULL REFERENCES `governance.design_state`
- `state_version` BIGINT NOT NULL
- `state_hash` TEXT NOT NULL
- `updated_at` TIMESTAMPTZ NOT NULL
- `updated_by` UUID NOT NULL
- unique `(design_id, state_version)`

The head is mutable operational state; historical Design State rows remain immutable.

## CAS Boundary
A SECURITY DEFINER controlled function performs one atomic transaction boundary:
1. lock the single `design_head` row `FOR UPDATE`;
2. compare `expected_state_version` and `expected_state_hash` with the current head;
3. reject with `STALE_DESIGN_HEAD` on mismatch;
4. validate canonical request/idempotency identity;
5. validate lifecycle and authorization requirements;
6. create the new immutable Design State row/version;
7. atomically advance `design_head` to the new version;
8. emit immutable transition evidence.

The caller never directly updates `design_head`.

## Two-writer invariant
Given writers A and B reading the same head version N:
- A CAS(N → N+1) succeeds.
- B CAS(N → N+1) must fail with `STALE_DESIGN_HEAD` after A commits.
- B must not partially mutate Core, Design State, or transition evidence.
- Retrying B requires rereading the new authoritative head and creating a new canonical request identity where appropriate.

## Idempotency invariant
Exact replay of the same canonical identity returns the original transition event/application result and does not advance the head twice. Idempotency lookup must occur before predecessor validation for an exact replay, while mismatched identity/state inputs must not bypass stale-state protection.

## Non-goals
No production migration, production data mutation, LLM-controlled write, or infrastructure change is authorized by this design.

## M09-N05 verification
Disposable PostgreSQL only:
- seed one Design Head at version N;
- create two independent writer requests A and B, both expecting N and the same hash;
- execute A CAS and commit;
- execute B with the unchanged expected N/hash;
- assert B receives `STALE_DESIGN_HEAD`;
- assert exactly one head advancement exists;
- assert exactly one new immutable Design State exists;
- assert no partial Core/transition mutation from B;
- replay A with the same canonical identity and assert the original event/result is returned without another head advance.

**PASS condition:** one writer wins, the competing stale writer is atomically rejected, and exact replay is idempotent.
