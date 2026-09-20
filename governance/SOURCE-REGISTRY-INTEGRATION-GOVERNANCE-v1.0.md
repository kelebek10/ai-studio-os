# PAI-FORGE — SOURCE REGISTRY INTEGRATION GOVERNANCE

**Document:** SOURCE-REGISTRY-INTEGRATION-GOVERNANCE-v1.0.md  
**Version:** 1.0  
**Status:** PROPOSED — CONTROLLED REVIEW REQUIRED  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`  
**Date:** 2026-09-12

## 1. Decision

The **Source Registry** is the sole authoritative owner of source-system identity used by PAI-FORGE provenance.

`source_system` values in Evidence, RAW and related provenance records must resolve to a registered source identity. Free-text source names are not authoritative.

## 2. Authority hierarchy

1. Human Project Owner — final governance authority.
2. Source Registry — authoritative source identity and lifecycle.
3. PostgreSQL constraints/functions — technical enforcement.
4. Evidence/RAW/Research records — consumers carrying source references.
5. External sources, Sheets, n8n and AI systems — input/proposal only.

## 3. Source identity

Each source has a stable registry identity and immutable machine-readable `code`.

Minimum registry semantics:

- `source_id`
- `code`
- `name`
- `source_class`
- `authority_level`
- `status`
- `created_at`
- `updated_at`

`code` identifies one source meaning and must never be silently reassigned to another source.

Source identity is distinct from source version, captured record, content hash and evidence verification state.

## 4. Source version boundary

A source system and a source revision/version are separate concepts.

Registry identity answers **which source**.

The provenance record answers **which source version/revision was captured** and **what exact content was captured**.

Therefore:

`source_id != source_version != evidence_id != content_hash`

A source revision creates a new provenance/evidence record; it does not mutate historical evidence.

## 5. Integration model

The preferred Core representation is a real FK/reference to the Source Registry rather than an uncontrolled text vocabulary.

Existing fields such as:

`source_system text`

are therefore transitional design notation only and must be reconciled during PostgreSQL schema review.

The migration design must choose one authoritative physical representation, preferably:

`source_id -> registry.source`

while preserving source version/revision and content hash on the evidence/RAW record.

No duplicate source vocabulary should remain authoritative.

## 6. Source lifecycle

Minimum lifecycle:

`ACTIVE | DEPRECATED`

DEPRECATED means the source remains historically resolvable but should not be used for new records unless explicitly permitted by governance.

Historical Evidence/RAW records are never rewritten merely because a source is deprecated.

Physical deletion of a source referenced by historical provenance is prohibited.

## 7. New source onboarding

A new source requires a governed proposal containing at minimum:

- source code
- source name
- source class
- authority level
- purpose/use
- provenance expectations
- version/revision strategy
- evidence requirements
- license/access constraints where relevant
- compatibility/migration impact
- proposer and provenance

Human Project Owner approval is required before activation.

AI, n8n, Google Sheets or an external source cannot activate itself in the registry.

## 8. Source class and authority

`source_class` and `authority_level` are registry metadata, not identity.

They must not be inferred from the source code string at runtime.

A source's authority level does not automatically make its data scientifically authoritative. Scientific verification remains a separate controlled process.

## 9. Provenance invariants

For each authoritative provenance record:

- source identity is resolvable;
- source revision/version is preserved;
- captured content hash is preserved where applicable;
- capture timestamp is preserved;
- verification state is separate from source authority;
- historical provenance remains reconstructable.

Source Registry changes must never rewrite historical provenance semantics.

## 10. RAW and Evidence integration

`research.raw_record` must preserve the original source reference and payload.

`evidence.record` must preserve the source reference, source version and content hash.

n8n may transport and validate source references but cannot create or mutate authoritative source identities or Core knowledge.

## 11. AI and proposal boundary

AI models may propose:

- source discovery
- source classification
- source metadata
- source authority assessment

They cannot directly create, activate, deprecate or repurpose a Source Registry entry.

Such proposals enter the controlled research/proposal workflow and require human governance.

## 12. Tenant boundary

Source identity is global scientific/provenance infrastructure.

A tenant may reference a source but cannot redefine the global meaning, authority or identity of that source.

Tenant-specific source preferences belong in a separate tenant configuration layer.

## 13. Scale and migration requirement

Adding a new source must not require altering the Evidence or Core table schema.

The Source Registry must remain efficient at the S1–S4 scale defined by `SCALE-TEST-PLAN-v1.0.md`.

Existing source records must be migrated deterministically from transitional text representation to the authoritative registry reference before production migration is approved.

## 14. Prohibitions

- No free-text source vocabulary as an authoritative model.
- No AI direct registry mutation.
- No n8n direct registry mutation.
- No source self-registration into authoritative Core.
- No source-code reuse for a different source meaning.
- No deletion of historically referenced source identity.
- No automatic scientific trust decision from `authority_level`.
- No production migration authorized by this document.

## 15. Approval gate

This document remains **PROPOSED — CONTROLLED REVIEW REQUIRED** until reconciled with:

- `REGISTRY-ARCHITECTURE-v1.0.md`
- `POSTGRESQL-SCHEMA-BLUEPRINT-v1.1.md`
- `KNOWLEDGE-RECORD-RECONCILIATION-v1.0.md`
- `SCALE-TEST-PLAN-v1.0.md`

Human Project Owner approval is required before Source Registry integration becomes an approved production design.

**PRODUCTION MIGRATION = BLOCKED.**
