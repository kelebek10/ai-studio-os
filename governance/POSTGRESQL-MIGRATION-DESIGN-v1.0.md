# PAI-FORGE — PostgreSQL Migration Design v1.0

**Document:** POSTGRESQL-MIGRATION-DESIGN-v1.0.md  
**Version:** 1.0  
**Status:** CONTROLLED DESIGN  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`

## 1. Purpose

Define the controlled migration design from the approved PostgreSQL Blueprint to executable SQL. This artifact authorizes design only; it does not authorize production execution.

## 2. Preconditions

- PostgreSQL Blueprint v1.3 reviewed PASS.
- Contract–Blueprint alignment reviewed PASS.
- Schema migration remains blocked until Human Project Owner approval is recorded.
- `main` branch is out of scope.

## 3. Migration Order

1. Extensions and schemas.
2. Roles and privilege boundaries.
3. Controlled ENUM/CHECK domains.
4. Core identity and relationship tables.
5. Knowledge, evidence and provenance tables.
6. Tenant/RLS foundations.
7. Research/RAW/proposal boundaries.
8. Constraint and immutable constraint-version tables.
9. Design State boundary.
10. Impact/dependency and feasibility tables.
11. Conflict/constraint bridge and alternatives.
12. Resolution and approval-event ledger.
13. Change Request/idempotency controls.
14. Immutable transition functions and enforcement triggers.
15. Indexes and query hardening.
16. Verification queries and migration test suite.

## 4. Security Boundary

Operational roles receive least privilege. Core mutation occurs only through controlled transition functions. Append-only records deny UPDATE/DELETE/TRUNCATE to operational writers. RLS is mandatory for tenant-scoped data.

## 5. Integrity Requirements

All foreign keys declare deletion policy. Historical records use `ON DELETE RESTRICT`. Exact Design State version/hash, applicable constraint-version set, canonical request identity and ruleset context must be validated atomically before Core mutation.

## 6. Idempotency / Concurrency

Migration must implement deterministic replay protection, expected-state validation and atomic transaction boundaries. Duplicate requests must resolve to the existing authoritative operation rather than create a second mutation.

## 7. Rollback Strategy

Migration is transactional where PostgreSQL permits. Destructive or irreversible operations require a separate migration step and explicit approval. Failed validation causes rollback with no partial Core mutation. No production data transformation is included in the first migration.

## 8. Verification Gates

Before execution authorization:

- schema object inventory matches Blueprint;
- all required FK and deletion policies verified;
- privileges verified by role;
- RLS policies tested with cross-tenant negative cases;
- append-only protections tested;
- idempotency replay tested;
- stale-state/concurrency rejection tested;
- conflict snapshot integrity tested;
- approval authorization tested;
- rollback test PASS;
- migration is repeatable and safely detectable as already applied.

## 9. Explicit Non-Goals

No production execution, no live data import, no Google Sheets→Core import, no n8n Core credentials, no AI direct Core mutation, no RAG/Qdrant/KG/MCP/multi-agent implementation.

**PRODUCTION MIGRATION = BLOCKED until controlled migration tests PASS and Human Project Owner approval is recorded.**
