# PAI-FORGE — PostgreSQL Schema Blueprint v1.2

**Document:** POSTGRESQL-SCHEMA-BLUEPRINT-v1.2.md  
**Version:** 1.2  
**Status:** REVISED — REGISTRY INTEGRATION FOR CONTROLLED RE-REVIEW  
**Owner:** Human Project Owner  
**Scope:** v1.1 Core/Identity/Provenance controls + Registry integration  
**Branch:** `phase-1-3-foundation`  
**Date:** 2026-09-12

## 1. Gate

This is a design artifact only. No production SQL execution, data import or infrastructure mutation is authorized.

v1.1 remains the baseline for all controls not explicitly changed here. v1.2 adds the Registry layer and migration sequencing.

**Production migration remains BLOCKED until the controlled review records PASS — ALL CONTROLS and Human Project Owner approval is recorded.**

## 2. Registry authority model

The Registry schema is authoritative for controlled vocabulary/identity metadata only.

Authority:

1. Human Project Owner — final governance authority.
2. Registry — authoritative vocabulary/identity state.
3. PostgreSQL constraints/functions — enforcement.
4. Domain records — consumers.
5. Sheets/n8n/AI/external sources — input/proposal only.

No duplicate authoritative vocabulary is permitted.

## 3. `registry.knowledge_type`

```text
knowledge_type_id bigint PRIMARY KEY
code              text NOT NULL UNIQUE
name              text NOT NULL
description       text NOT NULL
status            text NOT NULL CHECK (status IN ('ACTIVE','DEPRECATED'))
schema_version    text NOT NULL
created_at        timestamptz NOT NULL
updated_at        timestamptz NOT NULL
```

Rules:

- `code` is immutable semantic identity.
- DEPRECATED entries remain resolvable for historical Knowledge.
- New approved Knowledge may reference only ACTIVE types.
- A semantic change must not silently repurpose an existing code.
- Registry definition `schema_version` is independent of `core.knowledge.version`.

## 4. `registry.zone_type`

```text
zone_type_id      bigint PRIMARY KEY
code              text NOT NULL UNIQUE
name              text NOT NULL
description       text NOT NULL
status            text NOT NULL CHECK (status IN ('ACTIVE','DEPRECATED'))
hierarchy_allowed boolean NOT NULL
created_at        timestamptz NOT NULL
updated_at        timestamptz NOT NULL
```

Zone Type Registry is vocabulary metadata only.

It does not replace:

- `zone.zone_id`;
- `zone_current_state`;
- `zone_approval_event`;
- `zone_relationship`;
- Zone Dictionary authority;
- geographic parent/fallback governance.

## 5. `registry.source`

```text
source_id       bigint PRIMARY KEY
code            text NOT NULL UNIQUE
name            text NOT NULL
source_class    text NOT NULL
authority_level text NOT NULL
status          text NOT NULL CHECK (status IN ('ACTIVE','DEPRECATED'))
created_at      timestamptz NOT NULL
updated_at      timestamptz NOT NULL
```

`source_id` answers **which source**. It does not represent source revision, evidence identity or content hash.

`authority_level` is metadata and does not constitute scientific verification.

## 6. Core integration

### Knowledge

Target:

```text
core.knowledge.knowledge_type_id
    REFERENCES registry.knowledge_type(knowledge_type_id)
    ON DELETE RESTRICT
```

The existing `knowledge_type text` representation is transitional only during migration. It must not remain an independent authority.

### Zone

Target:

```text
core.zone.zone_type_id
    REFERENCES registry.zone_type(zone_type_id)
    ON DELETE RESTRICT
```

The FK must not alter Zone identity/lifecycle semantics.

### Evidence

Target:

```text
evidence.record.source_id
    REFERENCES registry.source(source_id)
    ON DELETE RESTRICT
```

Preserve `source_version`, `source_record_key`, `content_hash`, capture timestamp and verification state.

### RAW

Target:

```text
research.raw_record.source_id
    REFERENCES registry.source(source_id)
    ON DELETE RESTRICT
```

RAW payload and provenance remain immutable.

## 7. Transitional representation rule

During migration, legacy fields may temporarily coexist only as **non-authoritative compatibility/provenance data**.

They must never create a second vocabulary authority.

Examples:

- legacy `knowledge_type text` → compatibility mapping only;
- legacy `source_system text` → compatibility mapping only.

After deterministic backfill and validation, authoritative reads/writes use registry FKs.

Legacy columns may be retained temporarily for audit/reconciliation, but cannot drive business decisions once the FK authority gate is enabled.

## 8. Registry migration order

The controlled order is:

1. Governance freeze.
2. Create registry tables.
3. Validate/approve registry seed set.
4. Deterministically map existing Knowledge Type values.
5. Deterministically map existing Source values.
6. Reconcile Zone Type values with Zone Dictionary.
7. Add staged FK columns/constraints.
8. Backfill FK values.
9. Quarantine unresolved/ambiguous rows.
10. Validate zero unapproved unresolved mappings.
11. Activate FK-based authoritative reads/writes.
12. Remove legacy controlled-value authority.
13. Validate indexes, RLS, provenance and performance.
14. Run integrated PostgreSQL review.
15. Human Project Owner approval.
16. Production migration only after gate PASS.

## 9. Deterministic mapping rules

Mapping must be exact and reproducible.

For every legacy value:

`legacy value + mapping ruleset version -> exactly one registry identity`

Allowed outcomes:

- deterministic match;
- explicit approved alias;
- QUARANTINE / unresolved.

Forbidden:

- AI-only semantic guessing;
- silent normalization;
- automatic registry entry creation;
- automatic merge of distinct meanings.

## 10. Historical semantics

DEPRECATED registry entries remain valid references for historical rows.

Registry status changes do not rewrite:

- Knowledge history;
- Evidence;
- RAW;
- approvals;
- event history;
- provenance.

No referenced registry entry may be physically deleted.

## 11. Security / RLS integration

Registry tables are global governance infrastructure.

Tenant roles may read permitted registry metadata but cannot mutate authoritative registry state.

Only controlled governance/owner workflow may create, activate, deprecate or otherwise mutate registry definitions.

No n8n, AI, tenant or application role receives direct registry governance authority.

## 12. Index baseline

Mandatory indexes:

```text
registry.knowledge_type(code)
registry.zone_type(code)
registry.source(code)
core.knowledge(knowledge_type_id, state)
core.zone(zone_type_id)
evidence.record(source_id, source_version)
research.raw_record(source_id, source_record_key)
```

Unique constraints on registry `code` fields are authoritative identity constraints.

## 13. Compatibility with existing governance

v1.2 must remain consistent with:

- Identity Model constraint matrix;
- Zone Dictionary Schema v1.0;
- Zone Scope Data Contract v1.2;
- Knowledge Record Reconciliation v1.0;
- Registry Architecture v1.0;
- Knowledge Type Vocabulary Governance v1.0;
- Source Registry Integration Governance v1.0;
- Scale Test Plan v1.0;
- PostgreSQL Schema Review / 11-control checklist.

The existing `record_zone` M:N model and transaction-level scope/cardinality enforcement remain unchanged.

## 14. Migration safety gates

Before production:

- registry seed completeness = PASS;
- deterministic mapping = PASS;
- unresolved values = 0 except explicitly quarantined;
- duplicate mappings = 0;
- FK validation = PASS;
- historical references remain resolvable = PASS;
- RLS/security = PASS;
- scale tests = PASS;
- rollback plan = PASS;
- integrated schema review = PASS;
- Human Project Owner approval = YES.

Any failure keeps production migration BLOCKED.

## 15. Explicit prohibitions

No production SQL execution from this blueprint. No Google Sheets → Core import. No n8n Core write credentials. No AI direct registry/Core mutation. No automatic semantic mapping. No destructive historical rewrite. No Zone Dictionary replacement. No premature RAG/KG/MCP/multi-agent implementation.

## 16. Status

**REVISED — REGISTRY INTEGRATION FOR CONTROLLED RE-REVIEW**

This document defines the target architecture and migration order. It does not itself authorize migration.
