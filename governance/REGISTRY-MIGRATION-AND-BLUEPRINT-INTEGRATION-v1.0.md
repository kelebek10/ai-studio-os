# PAI-FORGE — REGISTRY MIGRATION AND BLUEPRINT INTEGRATION

**Document:** REGISTRY-MIGRATION-AND-BLUEPRINT-INTEGRATION-v1.0.md  
**Version:** 1.0  
**Status:** PROPOSED — CONTROLLED REVIEW REQUIRED  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`  
**Date:** 2026-09-12

## 1. Decision

Registry tables are governance/reference infrastructure. They must be integrated into the PostgreSQL Blueprint **before** production migration, but registry creation does not authorize production data migration.

The registry sequence is:

1. Knowledge Type Registry
2. Zone Type Registry
3. Source Registry
4. Core/evidence/RAW FK reconciliation
5. Integrated schema review
6. Migration design
7. Shadow/backfill validation
8. Production migration — only after all gates PASS and Human Project Owner approval.

No registry table is a substitute for the existing authoritative Zone Dictionary or Knowledge lifecycle model.

## 2. Phase 0 — Governance freeze

Before physical SQL migration design:

- approve Knowledge Type vocabulary ownership;
- approve Source Registry ownership/integration;
- confirm Zone Type Registry is vocabulary metadata only;
- reconcile all three with Registry Architecture;
- reconcile with Knowledge Record, Zone Dictionary, Zone Scope and Scale Test Plan;
- freeze authoritative ownership rules.

Until this gate passes, PostgreSQL Blueprint remains design-only.

## 3. Phase 1 — Registry schema design

The Blueprint v1.2 target must define three independent registries:

### Knowledge Type Registry

`registry.knowledge_type`

Purpose: authoritative vocabulary for Knowledge type semantics.

Core reference target:

`core.knowledge.knowledge_type_id -> registry.knowledge_type.knowledge_type_id`

The registry `code` remains the stable machine-readable identifier and must be unique/immutable.

### Zone Type Registry

`registry.zone_type`

Purpose: controlled vocabulary/metadata for Zone types.

It does NOT replace:

- `zone.zone_id`
- Zone lifecycle history
- Zone parent/relationship model
- Zone Dictionary authority

Core reference target:

`core.zone.zone_type_id -> registry.zone_type.zone_type_id`

### Source Registry

`registry.source`

Purpose: authoritative source identity for provenance.

Reference targets:

- `evidence.record.source_id -> registry.source.source_id`
- `research.raw_record.source_id -> registry.source.source_id`

Existing `source_system text` is transitional and must not remain an independent authoritative vocabulary.

## 4. Phase 2 — Blueprint reconciliation

The PostgreSQL Blueprint v1.2 must explicitly reconcile:

- registry ownership;
- FK targets;
- lifecycle/deprecation semantics;
- historical record behavior;
- source version semantics;
- Knowledge Type schema version vs Knowledge record version;
- Zone Type vs Zone identity;
- JSONB boundary;
- RLS/security roles;
- indexes;
- deletion behavior.

No duplicate vocabulary authority may remain.

## 5. Phase 3 — Data compatibility analysis

Before adding production FKs, existing data must be profiled for:

- unknown `knowledge_type` values;
- unknown `source_system` values;
- duplicate/ambiguous source names;
- invalid/deprecated values;
- nulls where the future FK is mandatory;
- historical values requiring preserved registry entries.

Unknown or ambiguous values go to controlled QUARANTINE; they are not silently normalized.

## 6. Phase 4 — Registry population

Populate registry entries before converting dependent columns to authoritative FKs.

Population rules:

- deterministic identifiers;
- immutable source/code identity;
- explicit provenance for imported registry definitions;
- no automatic semantic merge;
- no AI-only activation;
- Human Project Owner approval for activation.

Registry population is metadata migration, not scientific Knowledge migration.

## 7. Phase 5 — Dependent-column transition

After registry population and compatibility validation:

### Knowledge

Transition `core.knowledge.knowledge_type` from transitional controlled text representation to the authoritative registry FK.

Historical values must map deterministically to exactly one registry entry.

### Evidence / RAW

Transition `source_system` to `source_id` FK representation.

Preserve:

- source version/revision;
- source record key;
- content hash;
- captured timestamp;
- original payload where applicable.

Do not destroy original provenance during transition.

### Zone

Add/transition `zone_type_id` only after Zone Type Registry semantics are reconciled with the approved Zone Dictionary model.

Zone identity and lifecycle records are not migrated into the registry.

## 8. Phase 6 — Constraint activation

FK and lifecycle constraints are activated only after data compatibility passes.

Required controls include:

- valid FK resolution;
- ACTIVE/DEPRECATED behavior;
- immutable registry code;
- historical readability;
- explicit deletion policy;
- RLS/security compatibility;
- index coverage;
- transaction behavior;
- idempotency and provenance preservation.

Where PostgreSQL permits safe staged constraint validation, validation should precede enforcement where appropriate.

## 9. Phase 7 — Integrated schema review

Before any production migration, run one controlled integrated review against:

- PostgreSQL Blueprint v1.2
- Knowledge Type Governance
- Source Registry Governance
- Registry Architecture
- Knowledge Record Reconciliation
- Zone Dictionary Schema
- Zone Scope Data Contract
- Scale Test Plan
- PostgreSQL 11-control checklist

Required result:

**PASS — ALL CONTROLS**

Any unresolved critical control keeps production migration BLOCKED.

## 10. Phase 8 — Migration design

Only after integrated schema review PASS:

- write versioned migration scripts;
- define rollback strategy;
- define pre/post migration checks;
- define row-count/hash reconciliation;
- define FK validation queries;
- define lock/transaction strategy;
- define performance impact and index build strategy;
- define backup/restore checkpoint.

Migration scripts must be reviewed as code and governance artifacts before execution.

## 11. Phase 9 — Shadow/backfill validation

Before production cutover:

- run deterministic mapping in non-production/shadow environment;
- compare source and target counts;
- verify unmapped values = 0 except explicitly quarantined records;
- verify duplicate mappings = 0;
- verify historical provenance reconstruction;
- run scale queries from `SCALE-TEST-PLAN-v1.0.md`;
- verify RLS and write-authority boundaries.

Failure returns the process to schema/data analysis. No silent correction is permitted.

## 12. Phase 10 — Production migration gate

Production migration requires all of the following:

1. Registry governance approved.
2. Blueprint v1.2 approved.
3. PostgreSQL 11-control review PASS.
4. Data compatibility validation PASS.
5. Scale validation PASS for required tier.
6. Security/RLS validation PASS.
7. Rollback plan tested/accepted.
8. Human Project Owner explicit approval.

Until all eight conditions are satisfied:

**PRODUCTION MIGRATION = BLOCKED.**

## 13. Ordering rationale

Knowledge Type Registry comes first because `core.knowledge` is the central consumer and its type vocabulary must have one authoritative owner.

Zone Type Registry follows because it depends conceptually on the already-approved Zone Dictionary separation between identity and vocabulary.

Source Registry follows because provenance migration touches both RAW and Evidence and must preserve historical source/version semantics.

Dependent FKs come only after registry population and compatibility validation. This prevents creating authoritative constraints against incomplete vocabularies.

## 14. Blueprint v1.2 target architecture

Target logical structure:

```text
registry.knowledge_type
        │
        └── core.knowledge.knowledge_type_id

registry.zone_type
        │
        └── core.zone.zone_type_id

registry.source
        ├── evidence.record.source_id
        └── research.raw_record.source_id
```

The existing Zone Dictionary remains authoritative for Zone identity and lifecycle.

The registry layer owns vocabulary identity/metadata; Core tables own domain records and lifecycle state.

## 15. Explicit non-goals

This decision does NOT authorize:

- production SQL execution;
- Google Sheets import into Core;
- n8n Core write credentials;
- automatic source/Knowledge semantic merging;
- deletion of historical provenance;
- replacing Zone Dictionary with Zone Type Registry;
- premature Qdrant/RAG/KG/MCP/multi-agent implementation.

## 16. Approval gate

This document remains **PROPOSED — CONTROLLED REVIEW REQUIRED** until the three registry decisions and their Blueprint integration pass controlled cross-review.

**MAIN BRANCH MUST NOT BE CHANGED.**
