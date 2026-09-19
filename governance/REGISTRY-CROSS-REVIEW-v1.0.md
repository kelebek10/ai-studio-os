# PAI-FORGE — REGISTRY CROSS-REVIEW

**Document:** REGISTRY-CROSS-REVIEW-v1.0.md  
**Version:** 1.0  
**Status:** PROPOSED — CONTROLLED REVIEW REQUIRED  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`  
**Date:** 2026-09-12

## 1. Review Scope

Cross-review `REGISTRY-ARCHITECTURE-v1.0.md` against:

- PostgreSQL Blueprint v1.1
- Knowledge Record Reconciliation v1.0
- Zone Dictionary Schema v1.0
- Zone Scope Data Contract v1.2
- Scale Test Plan v1.0

No production mutation is authorized.

## 2. Findings

### R-X01 — Knowledge Type Registry vs Blueprint controlled value

**Finding:** Blueprint currently models `knowledge_type` as a controlled text value. A registry requires a future transition from hard-coded value lists to a referenced controlled vocabulary.

**Disposition:** OPEN.

**Required resolution:** Decide whether the registry becomes authoritative before SQL migration. Do not maintain two independent authoritative vocabularies.

### R-X02 — Zone Type Registry integration

**Finding:** Zone Dictionary is authoritative for Zone identity and lifecycle; a Zone Type Registry must remain vocabulary metadata and must not replace `zone_id` or lifecycle history.

**Disposition:** PASS WITH CONSTRAINT.

### R-X03 — Source Registry integration

**Finding:** Evidence and RAW currently use `source_system` text. A Source Registry is compatible, but migration must define whether source identity becomes an FK or remains an immutable external key with registry resolution.

**Disposition:** OPEN.

### R-X04 — JSONB boundary

**Finding:** Registry metadata must not become a reason to move deterministic fields into `payload` JSONB.

**Disposition:** PASS.

### R-X05 — Scale behavior

**Finding:** Registry lookups are low-cardinality reference access and should remain indexed. No partitioning or sharding is justified by the registry alone.

**Disposition:** PASS.

### R-X06 — Version semantics

**Finding:** Registry definition version must remain separate from Knowledge version, Evidence version and Zone lifecycle version.

**Disposition:** PASS.

### R-X07 — Deprecation / historical provenance

**Finding:** Deprecating a registry entry must not rewrite historical Knowledge, Evidence, RAW or provenance.

**Disposition:** PASS.

### R-X08 — Migration sequencing

**Finding:** Registry physical tables should not be migrated before the vocabulary ownership decision and PostgreSQL schema review are complete.

**Disposition:** OPEN.

## 3. Critical Decision

The registry architecture is **not yet APPROVED**.

The remaining blockers are limited and identifiable:

1. authoritative ownership of `knowledge_type` vocabulary;
2. authoritative Source identity integration;
3. migration ordering after the mandatory PostgreSQL review.

## 4. Recommended Architecture

Use registries as authoritative controlled vocabularies, while preserving domain identity in the existing Core entities.

Recommended future relations:

```text
core.knowledge.knowledge_type_id -> registry.knowledge_type
core.zone.zone_type_id            -> registry.zone_type
source references                 -> registry.source
```

However, these physical FK changes are **not authorized yet**. They require the final PostgreSQL schema decision.

## 5. Approval Gate

Before registry approval:

- resolve R-X01;
- resolve R-X03;
- define migration order for R-X08;
- reconcile the final decisions into PostgreSQL Blueprint v1.1;
- run the mandatory schema review controls;
- obtain Human Project Owner approval.

**Production migration remains BLOCKED.**
