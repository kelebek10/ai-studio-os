# PAI-FORGE — PostgreSQL Migration SQL Specification v1.0

**Version:** 1.0  
**Status:** SPECIFICATION — EXECUTION BLOCKED  
**Branch:** `phase-1-3-foundation`

## Objective

Define the executable SQL structure and ordering without executing against production.

## Specification Order

1. Transaction / migration marker
2. Required extensions
3. Schemas and ownership
4. Roles and least-privilege grants
5. Controlled ENUM/CHECK domains
6. Core identity and relationship tables
7. Knowledge/evidence/provenance
8. Tenant context and RLS
9. RAW/research/proposal boundary
10. Constraint and constraint-version tables
11. Design State / impact / feasibility
12. Conflict / alternative / resolution / approval ledger
13. Change Request and idempotency controls
14. Core transition functions
15. Immutability and append-only triggers
16. Foreign-key and deletion enforcement
17. Indexes and query paths
18. Verification queries
19. Migration completion marker

## Mandatory SQL Properties

- UUIDv7 identity strategy.
- Explicit FK and `ON DELETE RESTRICT` for historical/core identity records.
- No direct operational write path to Core tables.
- RLS on tenant-scoped data.
- Append-only enforcement for immutable history and approval records.
- Atomic expected-version/event-sequence checks.
- Deterministic idempotency key enforcement.
- Canonical request identity before mutation.
- Design State snapshot/version/hash integrity.
- Constraint-version references are immutable.
- Candidate/verified/approved states cannot bypass controlled transitions.
- JSONB limited to explicitly non-structural payloads.

## Test-Only Execution Boundary

The specification may later be rendered into migration SQL and executed only in an isolated disposable PostgreSQL test environment after the migration test plan is approved. Production execution is explicitly excluded from this specification.

## Prohibited

- Production execution.
- Production data import or transformation.
- n8n Core credentials.
- AI direct database mutation.
- Infrastructure mutation.
- Silent destructive migration.

## Next Gate

**Isolated PostgreSQL test implementation → migration test execution → security/integrity/replay/rollback verification.**
