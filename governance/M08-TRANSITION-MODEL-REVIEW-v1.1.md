# PAI-FORGE — M08 Transition Model Review v1.1

**Status:** BLOCKED — design correction required
**Branch:** `phase-1-3-foundation`

## Finding

The current non-production foundation makes `governance.conflict` and `governance.resolution` append-only through immutable triggers. Therefore a transition model based on direct UPDATE (`OPEN -> RESOLVED`, `PROPOSED -> APPROVED`, etc.) is incompatible with the existing history model.

## Required correction

M08 enforcement must use an append-only transition/event model for immutable records, while mutable workflow records such as `change_request` and `alternative` may use controlled transition functions where appropriate.

The controlled boundary must therefore distinguish:

1. **Mutable lifecycle state:** controlled function + transition matrix + authorization.
2. **Immutable lifecycle history:** new transition/event record, never UPDATE/DELETE of historical row.

## Gate

M08 remains BLOCKED until the transition contract is revised to this model and the disposable non-production implementation passes positive, negative, stale-state, authorization, direct-mutation, and rollback tests.

Production remains blocked; no production database mutation.
