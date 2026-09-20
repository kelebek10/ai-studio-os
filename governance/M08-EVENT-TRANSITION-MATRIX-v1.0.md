# PAI-FORGE — M08 Event Transition Matrix v1.0

**Status:** CONTROLLED TEST DESIGN
**Branch:** `phase-1-3-foundation`

## Principle

`conflict`, `resolution`, `design_state` and `approval_event` remain append-only. Lifecycle progression is represented by controlled transition events/new immutable records, not UPDATE of historical rows.

## Authoritative transitions

- Change Request: CANDIDATE→VERIFIED→APPROVED→APPLIED; CANDIDATE/VERIFIED/APPROVED→REJECTED; VERIFIED/APPROVED→STALE when authoritative state invalidates it.
- Alternative: CANDIDATE→FEASIBLE/INFEASIBLE/REJECTED; FEASIBLE→SELECTED; FEASIBLE→REJECTED; INFEASIBLE→REJECTED.
- Conflict: OPEN→RESOLVED, OPEN→REQUIRES_ENGINEERING_REVIEW, OPEN→SUPERSEDED, represented by controlled immutable transition evidence.
- Resolution: PROPOSED→APPROVED/REJECTED/ENGINEERING_REVIEW, represented by immutable successor/event evidence.

## Mandatory checks

Every transition must validate predecessor state, expected Design State version/hash, applicable constraint-version snapshot, canonical request/idempotency identity and authorization. Invalid or stale transitions must fail atomically. Safety-vs-safety conflicts cannot bypass Engineering Review. `PARTIALLY_FEASIBLE` cannot authorize application.

## Direct mutation rule

Historical rows are immutable. Operational writers cannot bypass the controlled transition boundary with UPDATE/DELETE.

## M08 gate

PASS only after disposable non-production tests prove valid transitions, invalid transition rejection, stale-state rejection, authorization rejection, direct mutation rejection and atomic rollback.

Production remains BLOCKED.
