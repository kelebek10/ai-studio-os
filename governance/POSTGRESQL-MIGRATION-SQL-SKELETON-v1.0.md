# PAI-FORGE — PostgreSQL Migration SQL Skeleton v1.0

**Version:** 1.0  
**Status:** DESIGN ONLY — NOT EXECUTABLE  
**Branch:** `phase-1-3-foundation`

## Purpose

Define the ordering and control boundaries for future PostgreSQL migration scripts. This document contains no production-ready SQL and must not be executed.

## Migration Sequence

```text
00 preflight / target safety
01 extensions and namespaces
02 controlled domains / enum or CHECK contracts
03 tenant + security context primitives
04 Core identity tables
05 evidence / research boundaries
06 knowledge and provenance
07 constraint + constraint_version
08 design_state + impact_dependency
09 feasibility_evaluation
10 conflict + conflict_constraint
11 alternative + resolution
12 approval_event
13 change_request / idempotency
14 indexes and query paths
15 immutable triggers / transition functions
16 RLS policies
17 grants / revokes
18 verification queries
19 rollback marker / migration ledger
```

## Mandatory Design Rules

- Every step has an explicit dependency and rollback consideration.
- Extensions are limited to approved requirements, including PostGIS where required.
- Core identity references use immutable identifiers; entity identity is never recycled.
- Foreign keys default to restrictive deletion semantics unless a contract explicitly permits otherwise.
- JSONB is limited to non-structural payloads; authoritative relational fields remain typed columns.
- Core write access is granted only to the approved Core writer boundary.
- n8n, LLM-facing and research roles receive no direct Core mutation privilege.
- RLS is evaluated before application-level tenant filtering is trusted.
- Append-only ledgers use database-enforced immutability, not application convention alone.
- Controlled state transitions occur through approved database functions or an equivalent privileged boundary.
- Optimistic concurrency, event sequencing and idempotency are separate controls.
- Migration scripts must be transaction-aware and support explicit recovery/rollback procedures.

## SQL Layering Contract

Future implementation must separate:

1. DDL/schema creation
2. security roles and grants
3. functions/triggers
4. RLS policies
5. indexes
6. verification tests
7. migration ledger / version marker

No single script may silently combine schema creation with data import or production cutover.

## Production Gate

This skeleton is not production authorization. A future executable migration requires a separate reviewed SQL artifact, successful Migration Design Review, security verification, rollback verification and explicit Human Project Owner approval.
