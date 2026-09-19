# PAI-FORGE — Identity Model v1.2 Constraint Matrix

**Status:** APPROVED FOR SCHEMA DESIGN  
**Scope:** P0 + P1 Identity Model controls  
**Authority:** Human Project Owner

## Purpose

This document records the finalized PostgreSQL integrity contract before schema implementation.

## Constraint Matrix

| ID | Rule | PostgreSQL enforcement | Test |
|---|---|---|---|
| C-01 | `expected_version != event_sequence != idempotency_key` | Separate columns and indexes/constraints | Retry and stale-version tests remain distinct |
| C-02 | Event sequence monotonic/history-safe | UNIQUE + transaction/sequence mechanism | Duplicate sequence rejected |
| C-03 | Idempotency | UNIQUE `idempotency_key` | Same request cannot create two logical approvals |
| C-04 | Optimistic concurrency | Version + conditional transition | Concurrent reviewer produces conflict |
| C-05 | Approval immutable | INSERT-only DB role; no UPDATE/DELETE | Mutation denied |
| C-06 | Entity cannot be physically deleted | Core role has no DELETE | DELETE denied |
| C-07 | Merge != delete | Relationship/event model | Old entity survives merge |
| C-08 | Split has no automatic knowledge migration | Controlled workflow + FK integrity | Split does not silently move knowledge |
| C-09 | Relationship type controlled | CHECK/ENUM | Invalid type rejected |
| C-10 | Duplicate relationships prohibited | UNIQUE `(from_entity_id,to_entity_id,relationship_type)` | Duplicate rejected |
| C-11 | Evidence↔Knowledge is M:N | Composite PK/UNIQUE | Duplicate link rejected |
| C-12 | Evidence cannot be deleted | Core role has no DELETE | DELETE denied |
| C-13 | Evidence invalidation does not cascade to knowledge | No destructive cascade; governed workflow | Knowledge remains unchanged until review |
| C-14 | Knowledge states distinct | CHECK/ENUM | Invalid state rejected |
| C-15 | `is_current` is non-authoritative | Optional materialized/partial index only | State history remains authoritative |
| C-16 | AI proposal cannot write Core | Separate schema/role permissions | Core mutation denied |
| C-17 | Proposal != approval | Separate tables/workflow | Proposal alone cannot change Core |
| C-18 | Proposal fingerprint | UNIQUE fingerprint | Duplicate proposal detected |
| C-19 | Business key != identity | Lookup index, never PK/FK | Business-key change preserves entity_id |
| C-20 | Canonicalization deterministic | Ruleset version + deterministic key | Same input/ruleset gives same key |
| C-21 | Canonicalization collision is not auto-merge | UNIQUE + collision workflow | Collision requires review |
| C-22 | Actor provenance immutable | Snapshot fields + INSERT-only history | Historical role cannot be rewritten |
| C-23 | AI model/version provenance | Immutable model_id/model_version | Model update does not alter history |
| C-24 | Scientific identity is global | No tenant ownership on global entity | Multiple tenants can reference same entity |
| C-25 | Tenant isolation | tenant_id + FK + RLS/role policy | Tenant A cannot access Tenant B data |
| C-26 | Tenant cannot mutate global identity | Tenant role lacks mutation permissions | Mutation denied |
| C-27 | Tenant override is separate | Dedicated tenant relation + FK | Override does not alter global knowledge |
| C-28 | RAW is immutable | RAW writer INSERT-only; UPDATE/DELETE/TRUNCATE denied | n8n mutation denied |
| C-29 | RAW cannot write Core | Separate DB roles/schema permissions | Direct Core write denied |
| C-30 | Referential integrity | FK + controlled ON DELETE behavior | Invalid references rejected |
| C-31 | Required fields | NOT NULL | Missing mandatory provenance/state rejected |
| C-32 | State Transition Authority | Core writes only through controlled workflow/service role | Direct state mutation denied |
| C-33 | Historical preservation | No hard delete; event/history retained | Historical state remains queryable |
| C-34 | Tenant ID != scientific ID | Separate namespaces/FKs | Tenant changes do not alter entity_id |

## Implementation Gate

- Constraint Matrix: APPROVED
- Schema Design: AUTHORIZED
- PostgreSQL Migration: NOT YET EXECUTED
- Production Database Change: BLOCKED
- Main Branch: UNCHANGED

## Next Step

Create the PostgreSQL schema blueprint from this matrix. Do not execute production migrations until schema review passes.
