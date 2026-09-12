# PEYZAJ AI / PAI-FORGE — CURRENT STATE

**Document:** CURRENT-STATE.md  
**Version:** 1.2  
**Status:** CONTROLLED BASELINE  
**Classification:** PROJECT CONTROL  
**Owner:** Human Project Owner  
**Location:** `governance/CURRENT-STATE.md`  
**Last Updated:** 2026-09-12

## 1. Purpose

This document records the authoritative current state of the PEYZAJ AI / PAI-FORGE project at a specific point in time.

It answers one question:

> **Where are we now?**

It is not a roadmap, architecture replacement, or implementation specification. It is a controlled project-state snapshot used to prevent loss of context, uncontrolled drift, and accidental rework.

## 2. Current Phase

**Phase:** Phase 1–3 Foundation — Controlled PostgreSQL Schema Design

**Completed gates:**
- ADIM 1 — Repository & Governance Audit: **GO**
- ADIM 2 — Project Control / Governance Synchronization: **GO**
- Identity Model v1.2 Constraint Matrix: **APPROVED FOR SCHEMA DESIGN**
- Decision Recording Standard: **APPROVED**
- Project Handoff: **APPROVED**
- Zone Dictionary Schema v1.0: **APPROVED**

**Current gate:** PostgreSQL Schema Design / Controlled Re-Review

**Next gate:** Schema Review v1.1 — PASS/FAIL — followed by Human Project Owner Approval

Production implementation and database migration remain blocked until the complete schema passes controlled review and approval.

## 3. Repository State

- Repository: `kelebek10/ai-studio-os`
- Active development branch: `phase-1-3-foundation`
- Protected baseline branch: `main`
- Latest approved governance artifact: `governance/ZONE-DICTIONARY-SCHEMA-v1.0.md`
- Latest known governance commit: `bfeb2c8ea0822386713dd73e5f9f4abb43abd6d5`
- Foundation and governance changes remain confined to the development branch.
- Production directories on Oracle Cloud remain separate from this repository.
- `main` remains untouched by this governance work.

## 4. Governance Baseline

Foundational controls:

1. `PAI-FORGE-001-ARCHITECTURE-CONSTITUTION.md`
2. `AI-GOVERNANCE.md`
3. `AI-ROLE-MATRIX.md`
4. `CORE-RESEARCH-BOUNDARY.md`
5. `DECISION-POLICY.md`
6. `EVIDENCE-STANDARD.md`
7. `RESEARCH-PROTOCOL.md`

Approved control documents:

8. `DECISION-RECORDING-STANDARD.md`
9. `PROJECT-HANDOFF.md`
10. `IDENTITY-MODEL-v1.2-CONSTRAINT-MATRIX.md`
11. `ZONE-DICTIONARY-SCHEMA-v1.0.md`

PostgreSQL schema control artifacts:

12. `POSTGRESQL-SCHEMA-BLUEPRINT-v1.0.md` — superseded
13. `POSTGRESQL-SCHEMA-BLUEPRINT-v1.1.md` — revised, awaiting re-review
14. `POSTGRESQL-SCHEMA-REVIEW-v1.0.md` — revision-required review
15. `POSTGRESQL-SCHEMA-REVIEW-CHECKLIST-v1.0.md` — controlled re-review checklist
16. `POSTGRESQL-SCHEMA-REVISION-ORDER-v1.0.md` — approved dependency order

No later implementation may bypass these records.

## 5. Architectural Baseline

```text
Structured Data
      ↓
Deterministic Rules / Calculations
      ↓
Semantic Retrieval
      ↓
LLM Explanation / Orchestration
      ↓
Output Validation
      ↓
Human Approval
```

**Structured-first → Semantic-second → LLM-last.**

LLMs are not authoritative for botanical facts, environmental measurements, scientific evidence, or deterministic calculations.

## 6. Core Boundary

Core is the trusted project knowledge layer. Data enters Core only after required evidence, validation, verification and approval gates.

> **n8n must not merely be configured not to write to Core; it must be technically unable to write to Core.**

No automation receives Core write credentials without an explicit approved security decision.

## 7. Data Ingestion Baseline

```text
Google Sheets
    ↓
n8n transport / ingestion
    ↓
Immutable RAW record
    ↓
Technical validation
    ↓
Evidence / provenance linkage
    ↓
Scientific screening and verification
    ↓
Human approval
    ↓
Core
```

RAW preserves the original payload and is never silently normalized, corrected or scientifically transformed. Technical validation and scientific verification remain separate. Idempotency does not depend solely on spreadsheet row number.

## 8. Identity Model v1.2

**APPROVED FOR SCHEMA DESIGN.**

Its 34 constraints are the authoritative integrity contract covering identity separation, version/event controls, immutability, evidence/knowledge separation, tenant isolation, AI proposal separation, provenance, canonicalization and controlled state transitions.

No PostgreSQL migration has been executed.

## 9. Zone Dictionary Status

`ZONE-DICTIONARY-SCHEMA-v1.0.md` is **APPROVED** as a design artifact.

Approved controls include immutable identity/current-state separation, explicit parent relationships, separate scientific fallback semantics, controlled microclimate criteria, immutable approval history, typed approval targets, `expected_version`, `event_sequence`, `idempotency_key`, versioned microclimate profiles, normalized `record_zone`, and role boundaries.

This approval does **not** authorize production migration or physical deployment.

The approved Zone Model and Zone Scope Data Contract must also exist as durable governance records before the schema documentation is considered complete.

## 10. PostgreSQL Schema Status

Current blueprint: `POSTGRESQL-SCHEMA-BLUEPRINT-v1.1.md`.

It incorporates the 11 prior review findings plus hardening for idempotency, concurrency, immutability, provenance, RLS, canonicalization, deletion semantics and controlled Core transitions.

**Status: NOT YET APPROVED.** It remains a design artifact pending controlled re-review.

Review sequence:

```text
Core Write Authority
        ↓
Tenant RLS + FK/Delete
        ↓
Immutability
        ↓
Event Sequence
        ↓
Idempotency
        ↓
Required Fields + Relationship Types
        ↓
Canonicalization
        ↓
Proposal → Approval Integrity
        ↓
Index / Query Hardening
        ↓
PASS — ALL CONTROLS
        ↓
Human Project Owner Approval
```

No SQL migration is authorized before the complete sequence passes.

## 11. Open Gates / Critical Completeness Checks

1. PostgreSQL schema is design-only; no physical implementation.
2. Blueprint v1.1 requires controlled re-review.
3. `knowledge_record` must be reconciled with Identity Model, Zone Model and Zone Scope Data Contract.
4. `record_zone.record_id` must reference the authoritative Knowledge record.
5. Scope/cardinality rules must be transactionally enforced across Knowledge and `record_zone`.
6. Approved Zone Model and Zone Scope Data Contract require durable GitHub synchronization.
7. Production migration is blocked.
8. RAW storage/security topology still requires concrete infrastructure controls later.
9. n8n credentials/workflow contracts remain subordinate to governance.
10. Evidence/provenance lifecycle requires concrete schema definitions.
11. Google Sheets remains candidate/source data only.
12. Scientific verification remains separate from technical ingestion.
13. Production infrastructure remains isolated until explicit integration approval.

## 12. Known Architecture Drift

`architecture/REPOSITORY-STRUCTURE.md` describes future areas such as `agents/`, `applications/`, `infrastructure/` and `docs/`. These are planned expansion, not current implementation requirements. They must not be created speculatively.

## 13. Completed Work

- Repository identity and foundational governance verified.
- Foundation checkpoint and `phase-1-3-foundation` established.
- `main` left untouched.
- ADIM 1 GO.
- Decision Recording Standard APPROVED.
- Identity Model v1.2 APPROVED FOR SCHEMA DESIGN.
- Project Handoff APPROVED.
- PostgreSQL Blueprint v1.0 reviewed and rejected for revision.
- Blueprint v1.1 created and hardened.
- Schema Review Checklist established.
- Schema Revision Order established.
- Zone Dictionary Schema v1.0 reviewed, hardened and APPROVED.
- Current state reconciled to the latest governance checkpoint.

## 14. Immediate Next Actions

1. Synchronize approved Zone Model and Zone Scope Data Contract into GitHub.
2. Design `knowledge_record` against Identity + Zone + Scope contracts.
3. Finalize `record_zone` FK and cross-table scope/cardinality enforcement.
4. Re-review Blueprint v1.1 against all 34 Identity controls, Zone controls and hardening checks.
5. Record Schema Review v1.1 as **PASS — ALL CONTROLS** only if objectively enforceable.
6. Obtain Human Project Owner approval.
7. Design a separate PostgreSQL migration plan only after approval.
8. Perform migration security/reversibility review before production execution.

## 15. Current Gate

### POSTGRESQL SCHEMA DESIGN / CONTROLLED RE-REVIEW

**Status:** IN PROGRESS — DESIGN ONLY

**GO condition:** Current state synchronized; Identity approved; Zone Dictionary approved; governance controls approved; Blueprint v1.1 exists; no uncontrolled production implementation.

**STOP condition:** unverified source→Core write; unauthorized automation Core credentials; destructive RAW mutation; migration before approval; bypassed decision/version control; or unresolved contradiction between Identity, Zone, Knowledge, Evidence, Provenance and Tenant contracts.

## 16. Change Control

Update this document for every material phase, architecture, repository, security, data lifecycle, production, or AI-orchestration change. Material changes must be traceable through Git history and, where appropriate, a decision record.

---

**Source of Truth Rule:** The repository and versioned governance/decision records are the durable project control layer. Conversational context may assist execution but is not the sole authoritative project record.
