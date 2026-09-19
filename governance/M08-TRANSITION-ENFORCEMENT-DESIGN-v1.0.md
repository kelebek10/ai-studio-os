# PAI-FORGE — M08 Transition Enforcement Design v1.0

**Status:** CONTROLLED TEST DESIGN
**Branch:** `phase-1-3-foundation`
**Scope:** Non-production M08 enforcement only

## Objective

Enforce lifecycle transitions at the controlled database boundary. Direct status mutation is not authoritative.

## Required boundary

Controlled transition functions are the only authorized mutation path for workflow state. Direct operational UPDATE of controlled state is rejected.

## Transition model

- Change Request: `CANDIDATE -> VERIFIED -> APPROVED -> APPLIED`
- Change Request rejection: `CANDIDATE|VERIFIED|APPROVED -> REJECTED`
- Change Request staleness: authoritative state/version mismatch -> `STALE`
- Conflict: `OPEN -> RESOLVED` only after valid resolution; `OPEN -> REQUIRES_ENGINEERING_REVIEW` for unresolved safety-vs-safety cases; terminal states cannot be reopened by mutation.
- Alternative: `CANDIDATE -> FEASIBLE|INFEASIBLE|REJECTED`; `FEASIBLE -> SELECTED`; terminal/selected states cannot be arbitrarily rewritten.
- Resolution: `PROPOSED -> APPROVED|REJECTED|ENGINEERING_REVIEW`.

## Enforcement rules

1. Transition source state must match the expected current state.
2. Destination state must be in the explicit transition matrix.
3. Required Design State version/hash must match the request snapshot.
4. Required constraint-version snapshot must be preserved.
5. Approval-required transitions must validate authorized principal/role.
6. Safety-vs-safety conflicts cannot bypass Engineering Review.
7. `PARTIALLY_FEASIBLE` cannot authorize application.
8. Direct UPDATE of controlled workflow state is denied to operational writers.
9. Failed transition rolls back atomically.

## Test gate

M08 PASS requires positive valid transitions, negative invalid transitions, stale-state rejection, unauthorized approval rejection, direct-mutation rejection, and rollback evidence in a disposable non-production database.

Production execution remains blocked.
