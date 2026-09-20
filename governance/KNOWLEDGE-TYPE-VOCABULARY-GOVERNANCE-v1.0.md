# PAI-FORGE — KNOWLEDGE TYPE VOCABULARY GOVERNANCE

**Document:** KNOWLEDGE-TYPE-VOCABULARY-GOVERNANCE-v1.0.md  
**Version:** 1.0  
**Status:** PROPOSED — CONTROLLED REVIEW REQUIRED  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`  
**Date:** 2026-09-12

## 1. Decision

The **Knowledge Type Registry** is the sole authoritative owner of the `knowledge_type` vocabulary.

No application, Google Sheet, n8n workflow, AI model, source system, tenant, or `core.knowledge` payload may define or independently extend the authoritative vocabulary.

`core.knowledge.knowledge_type` references the registry's stable machine-readable code/identity and is constrained by the database.

## 2. Authority hierarchy

1. Human Project Owner — final governance authority.
2. Knowledge Type Registry — authoritative vocabulary/state.
3. PostgreSQL constraints/functions — technical enforcement.
4. Core Knowledge records — consumers of the vocabulary.
5. Research/Sheets/AI/source systems — proposal/input only.

## 3. Registry identity

Each Knowledge Type has a stable technical identity and a unique immutable `code`.

A code identifies one semantic concept for its entire lifetime. A deprecated code MUST NOT be reassigned to a different meaning.

Display names, descriptions and labels are mutable metadata; they are never identity.

## 4. Required registry semantics

Minimum controlled fields:

- `knowledge_type_id` — stable registry identity
- `code` — unique machine-readable identifier
- `name` — human-readable label
- `description` — semantic definition
- `status` — ACTIVE / DEPRECATED
- `schema_version` — contract version for the type
- `created_at`
- `updated_at`

A type may be used by new Core records only while ACTIVE.

DEPRECATED types remain valid for historical records and are not rewritten merely because their vocabulary status changes.

## 5. Creation rule

A new Knowledge Type requires a governed proposal containing at minimum:

- proposed code
- semantic definition
- scope of use
- deterministic fields required, if any
- JSONB attributes, if any
- validation rules
- evidence requirements
- compatibility impact
- migration impact
- proposed schema version
- proposer/actor provenance

Approval by the Human Project Owner is required before the type becomes ACTIVE.

AI-generated proposals are advisory only and cannot create or activate a type.

## 6. Naming and semantic rules

- Codes use stable machine-readable `snake_case` identifiers.
- One code = one semantic meaning.
- Synonyms must not create duplicate types unless they represent materially different semantics.
- A display-name change does not create a new type.
- A semantic change creates a new type code or a new controlled version according to compatibility rules; existing historical meaning must remain reconstructable.
- Type codes must not encode zone, tenant, source, language, model, or temporal state.

## 7. Versioning

`schema_version` describes the contract of the Knowledge Type, not the individual Knowledge record.

A Knowledge record's `version` remains independent and is used for optimistic concurrency/current-state control.

Backward-compatible contract changes may advance `schema_version` under controlled review.

Breaking semantic changes require a new type code unless an explicit migration decision proves historical meaning remains unambiguous.

## 8. Deprecation

Deprecation is non-destructive.

When a type becomes DEPRECATED:

- existing records remain valid historical data;
- no automatic Knowledge rewrite occurs;
- new records should not use the type;
- replacement type, if any, must be explicitly recorded;
- provenance and historical interpretation remain preserved.

No physical DELETE of a type used by historical Knowledge is permitted.

## 9. Database enforcement

Application validation is not authoritative.

The PostgreSQL implementation must ensure that:

- `knowledge_type` resolves to an existing registry entry;
- only ACTIVE types can be assigned to newly approved Knowledge;
- historical DEPRECATED types remain readable;
- registry codes are unique;
- a code cannot be silently repurposed.

The exact FK/code implementation is part of the PostgreSQL schema review and migration design.

## 10. JSONB boundary

Knowledge Type Registry governance does not authorize arbitrary JSONB schemas.

Any field used for deterministic filtering, joining, authorization, scope/cardinality enforcement, lifecycle control or scientific decision logic must be represented as a typed/controlled relational field or governed database value.

JSONB is reserved for extensible attributes that do not require those guarantees.

## 11. Source and Zone independence

Knowledge Type is independent of:

- Zone Type
- Zone identity
- Source identity
- Source version
- Tenant identity
- AI model identity
- Ruleset version

A type code must never be overloaded to encode these dimensions.

## 12. Change control

Every vocabulary change must produce a versioned governance decision containing:

- decision ID
- proposed change
- rationale
- compatibility classification
- affected records/systems
- migration requirement
- evidence/references
- actor
- approval date
- resulting registry version

No undocumented vocabulary change is permitted.

## 13. Scale requirement

Adding a new Knowledge Type must not require rewriting existing Knowledge rows or changing the physical `core.knowledge` table solely because a new type was introduced.

The design must remain practical at 1K, 10K, 100K and 1M Knowledge records.

## 14. Prohibitions

- No AI direct vocabulary mutation.
- No n8n direct vocabulary mutation.
- No Google Sheets authoritative vocabulary.
- No source system authoritative vocabulary.
- No tenant-specific global Knowledge Type definitions.
- No code reuse for a different semantic meaning.
- No destructive deletion of historically referenced types.
- No production migration authorized by this document.

## 15. Approval gate

This document remains **PROPOSED — CONTROLLED REVIEW REQUIRED** until reconciled with:

- `REGISTRY-ARCHITECTURE-v1.0.md`
- `POSTGRESQL-SCHEMA-BLUEPRINT-v1.1.md`
- `KNOWLEDGE-RECORD-RECONCILIATION-v1.0.md`
- `SCALE-TEST-PLAN-v1.0.md`

Human Project Owner approval is required before the vocabulary governance becomes an approved production design.

**PRODUCTION MIGRATION = BLOCKED.**
