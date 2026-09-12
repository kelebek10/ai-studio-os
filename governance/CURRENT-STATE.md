# PEYZAJ AI / PAI-FORGE — CURRENT STATE

**Document:** CURRENT-STATE.md  
**Version:** 1.1  
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

**Phase:** Phase 1–3 Foundation — Controlled Transition to Schema Design

**Completed gates:**
- ADIM 1 — Repository & Governance Audit: **GO**
- ADIM 2 — Project Control / Governance Synchronization: **GO**
- Identity Model v1.2 Constraint Matrix: **APPROVED FOR SCHEMA DESIGN**
- Decision Recording Standard: **APPROVED**
- Project Handoff: **APPROVED**

**Current gate:** PostgreSQL Schema Design

**Next gate:** Schema Review and Human Project Owner Approval

Production implementation and database migration remain blocked until schema review and approval are complete.

## 3. Repository State

- Repository: `kelebek10/ai-studio-os`
- Repository purpose: AI Studio OS / PAI-FORGE foundation
- Active development branch: `phase-1-3-foundation`
- Protected baseline branch: `main`
- Latest governance synchronization commit: `governance: synchronize current state before schema design`
- Foundation work and governance changes remain confined to the development branch.
- Production directories on Oracle Cloud remain separate from this repository and must not be mixed with the PAI-FORGE source-of-truth repository.
- `main` remains untouched by this governance synchronization.

## 4. Governance Baseline

The project governance baseline consists of the foundational governance documents plus the approved control documents created during the Phase 1–3 Foundation transition.

Foundational controls include:

1. `PAI-FORGE-001-ARCHITECTURE-CONSTITUTION.md`
2. `AI-GOVERNANCE.md`
3. `AI-ROLE-MATRIX.md`
4. `CORE-RESEARCH-BOUNDARY.md`
5. `DECISION-POLICY.md`
6. `EVIDENCE-STANDARD.md`
7. `RESEARCH-PROTOCOL.md`

Current approved control documents include:

8. `DECISION-RECORDING-STANDARD.md`
9. `PROJECT-HANDOFF.md`
10. `IDENTITY-MODEL-v1.2-CONSTRAINT-MATRIX.md`

These documents must not be recreated, silently replaced, or bypassed by later implementation work.

## 5. Current Repository Foundation

The controlled foundation currently contains:

```text
core/
evidence/
research/
tests/
architecture/
governance/
```

The intended controlled data/research flow is:

```text
External Source
      ↓
Research / Raw
      ↓
Screening
      ↓
Verification
      ↓
Approval
      ↓
Core
```

External information is not authoritative merely because it exists in a source, spreadsheet, model output, or research result.

## 6. Architectural Baseline

The governing architectural principle is:

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

Equivalent high-level principle:

> **Structured-first → Semantic-second → LLM-last**

The LLM layer is not the authority for botanical facts, environmental measurements, scientific evidence, or deterministic calculations.

## 7. Core Boundary

The Core is the trusted project knowledge layer.

Data may enter Core only after the required evidence, validation, verification, and approval gates have been satisfied.

A source label such as `source`, a status such as `KNOWN`, or a model-generated answer does not by itself constitute scientific verification or Core approval.

The long-term security principle for automation is:

> **n8n must not merely be configured not to write to Core; it must be technically unable to write to Core.**

No automation may receive Core write credentials unless a corresponding security decision is explicitly approved.

## 8. Data Ingestion Baseline

The initial plant dataset is maintained externally in Google Sheets and is treated as source/candidate data, not authoritative Core data.

The intended ingestion direction is:

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

### Binding principles

- RAW must preserve the original source payload.
- RAW must not be silently normalized, corrected, or scientifically transformed.
- Technical validation and scientific verification are separate concerns.
- Idempotency must not depend solely on spreadsheet row number.
- RAW immutability, provenance, idempotency, and security controls will be represented explicitly in the PostgreSQL schema blueprint.

## 9. Identity Model v1.2 Status

The Identity Model v1.2 Constraint Matrix is **APPROVED FOR SCHEMA DESIGN**.

Its 34 constraints are the authoritative integrity contract for PostgreSQL schema design, including identity separation, event/version controls, immutability, evidence/knowledge separation, tenant isolation, AI proposal separation, provenance, canonicalization, and controlled state transitions.

No PostgreSQL migration has been executed.

## 10. AI Team Baseline

The project may use:

- ChatGPT
- Claude
- Gemini
- Kimi

The models are replaceable components, not the permanent system authority.

No AI model may independently redefine Core truth or bypass governance controls.

## 11. Current Known Constraints

1. PostgreSQL schema design has not yet been implemented.
2. Production database migration has not been executed and is blocked.
3. RAW storage/security topology remains a design concern to be encoded in the schema and later infrastructure controls.
4. n8n workflow contracts and credential boundaries must remain subordinate to approved governance decisions.
5. Evidence/provenance records require concrete schema and lifecycle definitions.
6. Google Sheets remains an external candidate-data source.
7. Scientific verification remains separate from technical ingestion.
8. Production infrastructure remains isolated from the development repository until explicit integration decisions are approved.

## 12. Known Architecture Drift

`architecture/REPOSITORY-STRUCTURE.md` describes a broader future repository structure that includes areas such as `agents/`, `applications/`, `infrastructure/`, and `docs/`.

The current controlled foundation intentionally does not create all of these areas yet.

This remains **planned expansion / architecture drift requiring controlled reconciliation**, not a current blocker.

Future structure expansion must be justified by an approved phase requirement rather than created speculatively.

## 13. Completed Work

The following work has been completed and checked:

- Repository identity verified.
- Foundational governance baseline verified.
- Foundation directory structure created.
- Foundation checkpoint committed.
- Development branch established: `phase-1-3-foundation`.
- `main` branch left untouched by foundation and governance work.
- Initial architecture audit completed.
- ADIM 1 classified as **GO**.
- Decision Recording Standard established and **APPROVED**.
- Identity Model v1.2 Constraint Matrix established and **APPROVED FOR SCHEMA DESIGN**.
- Project Handoff established and **APPROVED**.
- CURRENT-STATE synchronized to the new governance checkpoint.

## 14. Immediate Next Actions

The controlled next sequence is:

1. Create `POSTGRESQL-SCHEMA-BLUEPRINT-v1.0`.
2. Map all Identity Model v1.2 constraints C-01 through C-34 to concrete PostgreSQL enforcement.
3. Define tables, relationships, keys, constraints, indexes, roles, permissions, RLS boundaries, immutable-history mechanisms, and state-transition controls.
4. Review the blueprint against the governance and Identity Model contracts.
5. Record the schema decision and obtain Human Project Owner approval.
6. Only after approval, design and execute a separate migration plan.

## 15. Current Gate

### POSTGRESQL SCHEMA DESIGN

**Status:** IN PROGRESS — DESIGN ONLY

**GO condition:**

- Current state synchronized.
- Identity Model v1.2 approved for schema design.
- Decision Recording Standard approved.
- Project Handoff approved.
- No uncontrolled production implementation introduced.

**STOP condition:**

- Any attempt to write unverified source data directly into Core.
- Any automation with unauthorized Core write credentials.
- Any destructive mutation of RAW without an approved control model.
- Any production migration before schema review and approval.
- Any architecture change that bypasses decision/version control.

## 16. Change Control

This document must be updated whenever a material project-state change occurs, including:

- phase transition,
- architecture decision,
- repository structure change,
- security boundary change,
- data lifecycle change,
- production deployment milestone,
- major AI orchestration change.

Material changes must be traceable through Git history and, where appropriate, a corresponding decision record.

---

**Source of Truth Rule:** The repository and its versioned governance/decision records are the durable project control layer. Conversational context may assist execution but must not be treated as the sole authoritative project record.
