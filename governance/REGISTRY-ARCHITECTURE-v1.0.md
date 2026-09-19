# PAI-FORGE — REGISTRY ARCHITECTURE

**Document:** REGISTRY-ARCHITECTURE-v1.0.md  
**Version:** 1.0  
**Status:** PROPOSED — CONTROLLED REVIEW REQUIRED  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`  
**Date:** 2026-09-12

## 1. Purpose

Define extensible registries for Knowledge types, Zone types and Source systems without requiring repeated structural migrations as PAI-FORGE scales.

## 2. Core principle

A registry controls vocabulary and lifecycle; it does not replace authoritative domain entities or identity.

Registry IDs are technical identities. Names, codes and labels are not authoritative domain identity.

## 3. Knowledge Type Registry

Conceptual fields:

- `knowledge_type_id`
- `code` — stable machine-readable key, unique
- `name`
- `description`
- `status` — ACTIVE / DEPRECATED
- `schema_version`
- `created_at`
- `updated_at`

Rules:

- Existing Knowledge rows retain their type identity when a type is deprecated.
- Deprecation does not rewrite historical Knowledge.
- New types are registry additions, not `core.knowledge` table migrations.
- Deterministic fields remain relational; registry metadata must not turn Core semantics into opaque JSONB.

## 4. Zone Type Registry

Conceptual fields:

- `zone_type_id`
- `code` — stable machine-readable key, unique
- `name`
- `description`
- `status` — ACTIVE / DEPRECATED
- `hierarchy_allowed`
- `created_at`
- `updated_at`

Rules:

- A new controlled Zone type must not require rewriting existing Zone or Knowledge rows.
- Zone type does not replace `zone_id`.
- Parent/child relationships remain explicit and separate from type vocabulary.
- Scientific fallback rules remain a separate human-approved mechanism.

## 5. Source Registry

Conceptual fields:

- `source_id`
- `code` — stable machine-readable key, unique
- `name`
- `source_class`
- `authority_level`
- `status` — ACTIVE / DEPRECATED
- `created_at`
- `updated_at`

Rules:

- A new source system is registered without altering Evidence/Core table structure.
- Source identity and source version remain separate.
- Provenance remains immutable at the record/event level.
- Registry status cannot retroactively rewrite historical provenance.

## 6. Versioning

Registry definition changes must be versioned independently from Knowledge versions, Zone lifecycle versions and Evidence versions.

A registry code must not be silently repurposed for a different semantic meaning.

Semantic replacement requires a new code and controlled deprecation of the old code.

## 7. JSONB boundary

Registries must not become a mechanism for moving deterministic business/scientific constraints into JSONB.

JSONB remains appropriate only for extensible attributes that do not require authoritative relational constraints, frequent filtering, joins, authorization or scientific decision enforcement.

## 8. Scale requirement

The registry design must remain operationally practical at S1–S4 of `SCALE-TEST-PLAN-v1.0.md`.

Registry lookup must be index-supported and must not become a high-cardinality join bottleneck.

## 9. Approval gate

This document is PROPOSED. It does not authorize physical PostgreSQL migration.

Before approval, the three registries must be reconciled with:

- PostgreSQL Blueprint v1.1
- Knowledge Record Reconciliation v1.0
- Zone Dictionary Schema v1.0
- Zone Scope Data Contract v1.2
- Scale Test Plan v1.0

**Production migration remains BLOCKED.**
