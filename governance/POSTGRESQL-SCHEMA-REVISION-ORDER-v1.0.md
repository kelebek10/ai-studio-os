# PAI-FORGE — PostgreSQL Schema Revision Order

**Document:** POSTGRESQL-SCHEMA-REVISION-ORDER-v1.0.md  
**Version:** 1.0  
**Status:** APPROVED FOR v1.1 REVISION PLANNING  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`

## Purpose

Define the dependency-aware order for resolving the 11 findings from PostgreSQL Schema Review. This is a planning/control artifact. It does not authorize a production migration.

## Dependency Table

| Step | Control | Matrix | Prerequisite | Depends on | Gate |
|---|---|---|---|---|---|
| 1 | Core write authority | C-16/C-32 | Roles defined | — | Core mutation boundary explicit |
| 2 | Tenant isolation / RLS | C-25 | Tenant-scoped tables identified | 1 | RLS + tenant policy explicit |
| 3 | FK / ON DELETE | C-30 | Table relationships defined | 1 | Every FK has explicit delete policy |
| 4 | Immutability | C-05/C-12/C-22/C-23 | Roles + relationships | 1, 2, 3 | Append-only boundaries enforceable |
| 5 | Event sequence | C-02 | Event/history model | 4 | Transaction-safe ordering defined |
| 6 | Idempotency | C-03 | Transaction model | 5 | Scope + unique key explicit |
| 7 | Required fields | C-31 | Tables stabilized | 1–6 | NOT NULL contract explicit |
| 8 | Relationship type | C-09/C-10 | Relationship table stabilized | 3, 7 | Controlled type + uniqueness |
| 9 | Canonicalization | C-20/C-21 | Identity constraints | 7, 8 | Deterministic key + collision state |
| 10 | Proposal → Approval integrity | C-05/C-17/C-18 | Core write + identity controls | 4, 6, 9 | Controlled transition, no direct Core mutation |
| 11 | Index/query hardening | — | Final schema/workflows | 1–10 | Indexes justified by access patterns |

## Parallelization Rules

- Steps 2 and 3 may proceed in parallel after Step 1.
- Steps 7 and 8 may proceed in parallel once their structural prerequisites are stable.
- Step 11 must remain last to avoid premature index optimization.

## Mandatory Review Gate

The v1.1 blueprint must pass every step above before SQL migration design is authorized.

**Production migration remains BLOCKED.**
