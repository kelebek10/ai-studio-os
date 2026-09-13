# PAI-FORGE — PostgreSQL Migration Test Matrix v1.0

**Version:** 1.0  
**Status:** DESIGN / EXECUTION BLOCKED  
**Branch:** `phase-1-3-foundation`

## Gate

This matrix validates migration design before any production execution. It does not authorize database mutation.

## Test Groups

| ID | Control | Expected |
|---|---|---|
| M01 | Schema dependency order | No object is created before its dependency |
| M02 | Controlled values | Closed values reject invalid states |
| M03 | Primary identity | UUIDv7 identity is unique and immutable |
| M04 | Foreign keys | Invalid references fail; destructive deletes are restricted |
| M05 | Tenant isolation | Cross-tenant access is denied by RLS |
| M06 | Core write boundary | Non-Core roles cannot mutate Core |
| M07 | Append-only history | UPDATE/DELETE on immutable ledgers is rejected |
| M08 | State transition | Only approved transition functions can change controlled state |
| M09 | Optimistic concurrency | Stale expected_version is rejected |
| M10 | Event sequencing | Duplicate/out-of-order event sequence is rejected |
| M11 | Idempotency | Same canonical request cannot create duplicate effects |
| M12 | Provenance | Required predecessor/reference chain is enforced |
| M13 | Candidate boundary | Candidate data cannot silently become verified/approved |
| M14 | Approval authority | Unauthorized approval principal is rejected |
| M15 | Constraint versioning | Historical constraint versions remain immutable |
| M16 | Design State integrity | Version/hash mismatch is rejected |
| M17 | Conflict integrity | Conflict binds exact design state and constraint versions |
| M18 | Feasibility authority | Deterministic feasibility result cannot be overridden by LLM |
| M19 | Partial feasibility | PARTIALLY_FEASIBLE cannot auto-apply |
| M20 | Non-destructive invalidation | Superseded/invalidated records remain auditable |
| M21 | Replay determinism | Same canonical input + ruleset produces same result |
| M22 | Transaction rollback | Failed migration step leaves no partial schema state |
| M23 | Forward/backward compatibility | Rollback path is documented and testable |
| M24 | Index/query paths | Required lookup paths use intended indexes |
| M25 | Security grants | Least-privilege grants match role matrix |
| M26 | Production safety | No test path can target production credentials |

## Required Review Modes

1. Static schema review
2. Security/privilege review
3. Integrity/FK review
4. RLS isolation test
5. Concurrency test
6. Idempotency/replay test
7. Rollback/recovery test
8. Performance/index sanity test

## PASS Rule

All applicable controls must PASS. Any unresolved P0/P1 integrity, security, authority or replay failure is **BLOCKED**.

## Explicit Non-Goals

- No production SQL execution
- No production data import
- No infrastructure mutation
- No Core write from n8n or LLM
