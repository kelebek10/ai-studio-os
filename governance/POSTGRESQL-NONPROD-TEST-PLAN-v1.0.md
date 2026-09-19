# PAI-FORGE — PostgreSQL Non-Production Test Plan v1.0

**Version:** 1.0  
**Status:** CONTROLLED TEST PLAN — EXECUTION BLOCKED PENDING TEST RUNTIME  
**Branch:** `phase-1-3-foundation`

## Purpose

Define the isolated disposable PostgreSQL test run for the approved migration design. This plan does not authorize production execution.

## Runtime Boundary

- Disposable PostgreSQL instance only.
- No production credentials.
- No live application data.
- No Google Sheets→Core import.
- No n8n Core credentials.
- No AI direct Core mutation.
- Destroy test instance after the run unless retained for reproducibility.

## Test Sequence

1. Preflight: PostgreSQL version, empty target, extensions.
2. Apply executable migration artifact when present.
3. Verify schema object inventory against Blueprint v1.3.
4. Verify ENUM/CHECK controlled values.
5. Verify primary/foreign keys and restrictive deletion.
6. Verify roles, grants and Core writer boundary.
7. Verify tenant RLS with positive and cross-tenant negative cases.
8. Verify append-only ledgers and immutable version records.
9. Verify controlled state-transition boundary.
10. Verify expected-state concurrency rejection.
11. Verify event sequencing.
12. Verify deterministic idempotency replay.
13. Verify Design State/hash and conflict snapshot integrity.
14. Verify candidate→verified→approved boundary.
15. Verify deterministic feasibility authority and PARTIALLY_FEASIBLE blocking.
16. Verify approval authorization and AI non-authorization.
17. Verify provenance and predecessor references.
18. Verify non-destructive invalidation/supersession.
19. Verify indexes and representative query plans.
20. Verify rollback/recovery.
21. Repeat migration on a fresh disposable target.
22. Record PASS/FAIL evidence.

## Gate

No production execution is permitted from this test plan. Production migration remains BLOCKED until the complete non-production test evidence passes and a separate Human Project Owner approval is recorded.
