# PAI-FORGE — M08 State Transition Contract v1.0

**Document:** M08-STATE-TRANSITION-CONTRACT-v1.0.md
**Version:** 1.0
**Status:** CONTROLLED DESIGN
**Owner:** Human Project Owner
**Branch:** `phase-1-3-foundation`

## Purpose

Define the minimum database-authoritative transition boundary required for M08. This contract does not authorize production migration or define the full application workflow.

## Authority

Controlled transition functions are authoritative. Direct operational UPDATE of lifecycle status is not authoritative and must be rejected for protected lifecycle tables.

## Required Transition Boundaries

### Change Request

Allowed:
- CANDIDATE -> VERIFIED
- VERIFIED -> APPROVED
- CANDIDATE -> REJECTED
- VERIFIED -> REJECTED
- APPROVED -> APPLIED
- VERIFIED/APPROVED -> STALE when authoritative Design State invalidates the request

Forbidden:
- REJECTED -> any active state
- APPLIED -> any other state
- direct status mutation bypassing transition function

### Alternative

Allowed:
- CANDIDATE -> FEASIBLE
- CANDIDATE -> INFEASIBLE
- FEASIBLE -> SELECTED
- FEASIBLE -> REJECTED
- INFEASIBLE -> REJECTED

A SELECTED or REJECTED alternative is terminal for that row.

### Conflict

Allowed:
- OPEN -> RESOLVED
- OPEN -> REQUIRES_ENGINEERING_REVIEW
- OPEN -> SUPERSEDED

Safety-vs-Safety conflict cannot transition directly to RESOLVED without Engineering Review.

### Resolution

Allowed:
- PROPOSED -> APPROVED
- PROPOSED -> REJECTED
- PROPOSED -> ENGINEERING_REVIEW

Historical resolution rows remain immutable; a later decision creates a new row.

## Atomic Preconditions

Every controlled transition must validate, within one transaction:

1. expected Design State version;
2. exact state hash where required;
3. applicable constraint-version snapshot;
4. canonical request/idempotency identity;
5. predecessor lifecycle state;
6. required authorization/approval;
7. resulting Core version where Core mutation follows.

Failure must rollback the complete transaction.

## Non-Goals

No production SQL execution, no application-layer workflow implementation, no AI authority, and no change to `main`.

## M08 Gate

M08 remains BLOCKED until this contract is implemented in a disposable non-production migration and negative/positive transition tests PASS.
