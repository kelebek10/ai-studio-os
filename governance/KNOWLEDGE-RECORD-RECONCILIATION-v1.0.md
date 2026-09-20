# PAI-FORGE — KNOWLEDGE RECORD RECONCILIATION

**Document:** KNOWLEDGE-RECORD-RECONCILIATION-v1.0.md  
**Version:** 1.0  
**Status:** PROPOSED — CONTROLLED REVIEW REQUIRED  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`  
**Date:** 2026-09-12

## 1. Finding

The PostgreSQL Blueprint v1.1 already defines the authoritative Core table as `core.knowledge`. The Zone Scope Data Contract uses the logical term `knowledge_record`.

Creating a second physical table named `knowledge_record` would create two competing sources of truth and unnecessary synchronization cost.

## 2. Decision Proposal

**Do not create a second physical Knowledge table.**

For PAI-FORGE:

- `core.knowledge` is the authoritative physical Knowledge record table.
- `knowledge_record` is the governance/data-contract logical name for an individual row in `core.knowledge`.
- `record_zone.record_id` will reference `core.knowledge(knowledge_id)`.
- A view, alias or compatibility name is not required unless an external interface later needs it.

This preserves a single source of truth.

## 3. Required Typed Scope Fields

The existing `payload jsonb` is not sufficient as the authoritative storage mechanism for fields that drive deterministic filtering, validation and relational constraints.

The integrated `core.knowledge` design MUST therefore expose these as typed columns:

```text
kayit_seviyesi  text NOT NULL CHECK (...)
cultivar_code   text NULL
kapsam          text NOT NULL CHECK (...)
```

The following semantic rule applies:

```text
kayit_seviyesi = TUR_DUZEYI  -> cultivar_code IS NULL
kayit_seviyesi = CESIT_DUZEYI -> cultivar_code IS NOT NULL
```

`botanical_name` should not become a second scientific identity source when the authoritative identity already exists in `core.entity`. The preferred rule is:

```text
core.entity.canonical_name = authoritative botanical identity
core.knowledge.entity_id   = owning scientific identity
```

If the source dataset requires a separately preserved botanical-name input, it belongs in provenance/raw/candidate data, not as a competing authoritative identity field.

## 4. Scope Model

`core.knowledge.kapsam` is the sole authoritative scope semantic:

```text
ZONA_OZEL | BOLGESEL | GENEL
```

`record_zone` is a normalized M:N relationship table:

```text
record_id       -> core.knowledge.knowledge_id
zone_id        -> core.zone.zone_id
relation_kind  -> ZONA_OZEL | BOLGESEL_UYE
```

Mandatory transaction-level invariants:

```text
GENEL       -> 0 record_zone rows
ZONA_OZEL   -> exactly 1 row, relation_kind=ZONA_OZEL
BOLGESEL    -> >=1 rows, relation_kind=BOLGESEL_UYE
NO MIX      -> never both relation kinds for one record
```

These invariants must be enforced by deferred transaction-level database logic, not by application convention.

## 5. Version / State Boundary

`core.knowledge.version` remains the authoritative optimistic-concurrency version for the Knowledge record.

`core.knowledge.state` remains authoritative current state.

Historical approval/event data remains in the existing append-only structures. Knowledge state transitions cannot be performed directly by AI, n8n, tenant application roles or proposal writers.

## 6. Structured-First Requirement

Fields used for deterministic filtering, joins, authorization, scope enforcement, lifecycle control or scientific decision logic must be typed relational fields or controlled database values.

`payload jsonb` remains suitable for extensible knowledge attributes that do not require authoritative relational constraints.

No critical scope semantics may be hidden only inside JSON.

## 7. Integration Impact

The following existing documents must be reconciled before approval:

1. `POSTGRESQL-SCHEMA-BLUEPRINT-v1.1.md`
2. `ZONE-SCOPE-DATA-CONTRACT.md`
3. `ZONE-DICTIONARY-SCHEMA-v1.0.md`

The physical `record_zone` FK must reference the single authoritative Knowledge table.

## 8. Approval Gate

This reconciliation is **PROPOSED** only.

It becomes APPROVED only after:

- integrated `core.knowledge` field design is reviewed,
- `record_zone` FK/cardinality design is complete,
- scope contract is reconciled,
- PostgreSQL schema review passes all mandatory controls,
- Human Project Owner approves the resulting integrated design.

**Production migration remains BLOCKED.**
