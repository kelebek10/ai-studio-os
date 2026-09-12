# PAI-FORGE — MIGRATION DESIGN & SHADOW VALIDATION

**Document:** MIGRATION-DESIGN-AND-SHADOW-VALIDATION-v1.0.md  
**Version:** 1.0  
**Status:** PROPOSED — CONTROLLED REVIEW REQUIRED  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`  
**Date:** 2026-09-12

## 1. Purpose

Define the controlled design for PostgreSQL registry migration and shadow/backfill validation. This document authorizes design and validation planning only. It does not authorize production SQL execution, production data mutation, or infrastructure change.

## 2. Preconditions

Migration design may proceed only against the approved governance contracts and the revised PostgreSQL Blueprint. Production migration remains blocked until every production gate passes.

Required inputs:
- Registry Architecture
- Knowledge Type Vocabulary Governance
- Source Registry Integration Governance
- Registry Migration and Blueprint Integration
- Knowledge Record Reconciliation
- Zone Dictionary Schema
- Zone Scope Data Contract
- Scale Test Plan
- PostgreSQL Schema Review Checklist

## 3. Migration Order

1. Freeze vocabulary and source identity governance.
2. Create registry structures: `registry.knowledge_type`, `registry.zone_type`, `registry.source`.
3. Seed only approved registry entries.
4. Deterministically map legacy `knowledge_type` values to `registry.knowledge_type`.
5. Deterministically map legacy `source_system` values to `registry.source`.
6. Quarantine unknown, ambiguous, duplicate-semantic, or unmappable values.
7. Introduce authoritative FK/reference columns.
8. Validate counts, mappings, nullability, uniqueness and provenance.
9. Enforce constraints only after shadow validation passes.
10. Remove transitional authoritative ambiguity only through an approved migration step.

## 4. Mapping Rules

Legacy mapping is deterministic and reviewable.

- Exact approved mapping is allowed.
- Normalization may use only a versioned deterministic ruleset.
- Ambiguous values are QUARANTINE, never silently guessed.
- One legacy value may not map to multiple registry identities without an explicit governed decision.
- A registry code may not be reused for another semantic meaning.
- Historical source version, source record key, content hash, timestamps and original payload remain unchanged.

## 5. Knowledge Type Transition

Target authoritative relation:

`core.knowledge.knowledge_type_id -> registry.knowledge_type.knowledge_type_id`

The existing text value is transitional only. Registry entries must exist before FK enforcement. ACTIVE status is required for newly approved records; DEPRECATED values remain resolvable for historical records.

## 6. Source Transition

Target authoritative relations:

`evidence.record.source_id -> registry.source.source_id`  
`research.raw_record.source_id -> registry.source.source_id`

`source_version`, `source_record_key`, content hash, capture metadata and payload remain independent provenance fields. Existing `source_system` values are transitional and cannot remain a second authoritative vocabulary.

## 7. Zone Type Transition

`registry.zone_type` is vocabulary metadata only. Zone identity and lifecycle remain authoritative in the Zone Dictionary. `zone_id` is never replaced by a type identifier.

## 8. Shadow Validation

Shadow validation must compare old and target representations without mutating production authoritative state.

Minimum checks:
- source row count = target row count where applicable;
- every mapped value resolves to exactly one registry identity;
- no unexpected NULLs;
- no duplicate registry codes;
- no semantic collisions;
- Knowledge scope/cardinality remains unchanged;
- `record_zone` relationships remain unchanged;
- evidence↔knowledge links remain unchanged;
- RAW payload hashes remain unchanged;
- historical provenance remains reconstructable;
- tenant isolation and role boundaries remain unchanged;
- query/index behavior is benchmarked at S1–S4.

## 9. Backfill Rules

Backfill is idempotent and restartable.

Each batch must have:
- deterministic source selection;
- stable mapping ruleset version;
- audit record;
- row counts before/after;
- failure/quarantine count;
- checksum/hash comparison where applicable.

No destructive cleanup is performed during backfill.

## 10. Rollback Design

Rollback must be defined before production migration approval.

Required properties:
- registry seed rollback;
- FK enforcement rollback path;
- transitional column preservation until validation is complete;
- restore checkpoint/backup validation;
- no irreversible deletion as part of mapping;
- explicit stop conditions.

A rollback plan that depends on reconstructing deleted source data is invalid.

## 11. Production Gate

Production migration remains **BLOCKED** until all are true:

1. PostgreSQL Blueprint receives final schema approval.
2. All 11 schema controls are PASS.
3. Registry governance records are approved.
4. Deterministic mapping coverage is 100% or all exceptions are explicitly quarantined and accepted.
5. Shadow validation passes all checks.
6. Scale benchmarks pass agreed thresholds.
7. RLS and write-authority tests pass.
8. Rollback/restore procedure is tested and accepted.
9. Human Project Owner gives explicit production approval.

## 12. Non-Goals

No production migration, no automatic semantic inference, no direct AI/Core mutation, no hard deletion of historical identity/provenance, no Qdrant/RAG/KG/MCP/multi-agent implementation.

## 13. Decision

This document defines the next controlled implementation phase: **Migration Design → Shadow Validation → Production Gate**.

Until the gate is explicitly passed, PostgreSQL remains a design target and production migration remains blocked.
