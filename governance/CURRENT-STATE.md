# PEYZAJ AI / PAI-FORGE — CURRENT STATE

**Document:** CURRENT-STATE.md  
**Version:** 1.0  
**Status:** CONTROLLED BASELINE  
**Classification:** PROJECT CONTROL  
**Owner:** Human Project Owner  
**Location:** `governance/CURRENT-STATE.md`  
**Last Updated:** 2026-09-09

## 1. Purpose

This document records the authoritative current state of the PEYZAJ AI / PAI-FORGE project at a specific point in time.

It answers one question:

> **Where are we now?**

It is not a roadmap, architecture replacement, or implementation specification. It is a controlled project-state snapshot used to prevent loss of context, uncontrolled drift, and accidental rework.

## 2. Current Phase

**Phase:** Foundation / Controlled Transition to Implementation

**Current gate:** ADIM 1 — Repository & Governance Audit completed with **GO**.

**Next gate:** ADIM 2 — Project Control Documents.

The project is not yet considered ready for uncontrolled production implementation. Implementation must proceed through explicit gates and recorded decisions.

## 3. Repository State

- Repository: `kelebek10/ai-studio-os`
- Repository purpose: AI Studio OS / PAI-FORGE foundation
- Active development branch: `phase-1-3-foundation`
- Protected baseline branch: `main`
- Foundation checkpoint commit: `22b17c3`
- Foundation checkpoint status: clean and synchronized with remote at the time of audit
- Production directories on Oracle Cloud remain separate from this repository and must not be mixed with the PAI-FORGE source-of-truth repository.
- CURRENT-STATE.md is maintained on the `phase-1-3-foundation` development branch. Foundation work described in this document must not modify the `main` branch.

## 4. Governance Baseline

The following seven governance documents already exist and are preserved as foundational controls:

1. `PAI-FORGE-001-ARCHITECTURE-CONSTITUTION.md`
2. `AI-GOVERNANCE.md`
3. `AI-ROLE-MATRIX.md`
4. `CORE-RESEARCH-BOUNDARY.md`
5. `DECISION-POLICY.md`
6. `EVIDENCE-STANDARD.md`
7. `RESEARCH-PROTOCOL.md`

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

The required security controls and their technical enforcement mechanism will be finalized in the Sheets → n8n → RAW architecture decision. Until that decision is approved, no automation may receive Core write credentials.

## 8. Data Ingestion Baseline

The initial plant dataset is maintained externally in Google Sheets and is treated as source/candidate data, not authoritative Core data.

Current example fields include:

- `botanical_name`
- `local_name`
- `zone_code`
- `water_need_lt_m2_yil`
- `data_status`
- `source`
- `verified_date`

`data_status` is the Sheets source's own label; it is separate from the pipeline state machine and carries no authority over pipeline state.

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

### Principles (binding)

- RAW must preserve the original source payload.
- RAW must not be silently normalized, corrected, or scientifically transformed.
- Technical validation and scientific verification are separate concerns.
- Idempotency must not depend solely on spreadsheet row number.

### Required Controls (pending ADIM 2 decision)

- Canonical payload hashing should be used for duplicate/revision detection.
- Hashing must be deterministic and based on the original payload according to a documented canonicalization policy.
- Rollback should use status/compensating events rather than destructive deletion.
- Schema drift and source revision must be detectable.

## 9. AI Team Baseline

The project may use:

- ChatGPT
- Claude
- Gemini
- Kimi

The models are replaceable components, not the permanent system authority.

The orchestration principle is:

```text
Mission
  ↓
Task Definition
  ↓
Specialist AI Execution
  ↓
Evidence / Validation
  ↓
Cross-check where required
  ↓
Human Approval
  ↓
Authoritative Project State
```

No AI model may independently redefine Core truth or bypass governance controls.

## 10. Current Known Constraints

1. The repository foundation is established, but implementation controls are still being formalized.
2. The RAW storage/security topology is defined as a target control but is not yet implemented in code or infrastructure.
3. n8n workflow contracts and credential boundaries are not yet finalized.
4. Evidence/provenance records still need concrete schemas and lifecycle rules.
5. The Google Sheets source must be treated as an external candidate-data source.
6. Scientific verification remains a separate gate from technical ingestion.
7. Production infrastructure must remain isolated from the development repository until explicit integration decisions are approved.

## 11. Known Architecture Drift

`architecture/REPOSITORY-STRUCTURE.md` describes a broader future repository structure that includes areas such as `agents/`, `applications/`, `infrastructure/`, and `docs/`.

The current controlled foundation intentionally does not create all of these areas yet.

This is recorded as **planned expansion / architecture drift requiring controlled reconciliation**, not as a current blocker.

Future structure expansion must be justified by an approved phase requirement rather than created speculatively.

## 12. Completed Work

The following work has been completed and checked:

- Repository identity verified.
- Seven foundational governance documents verified.
- Foundation directory structure created.
- Foundation checkpoint committed.
- Development branch established: `phase-1-3-foundation`.
- Main branch left untouched by foundation work.
- Repository synchronization verified at the foundation checkpoint.
- Initial architecture audit completed.
- ADIM 1 gate classified as **GO**.

## 13. Immediate Next Actions

The controlled next sequence is:

1. Establish `PROJECT-ROADMAP.md`.
2. Establish the detailed data-ingestion architecture decision document.
3. Establish the permanent decision registry entry for the Sheets → n8n → RAW boundary.
4. Establish n8n documentation boundaries before creating workflows.
5. Define RAW schema, immutability, provenance, idempotency, and security controls.
6. Only then begin implementation of the ingestion workflow.

## 14. Current Gate

### ADIM 2 — PROJECT CONTROL

**Status:** IN PROGRESS

**GO condition:**

- Current state documented.
- Roadmap documented.
- No contradiction with the seven foundational governance documents.
- No uncontrolled implementation introduced.

**STOP condition:**

- Any attempt to write unverified source data directly into Core.
- Any automation with Core write credentials.
- Any destructive mutation of RAW without an approved control model.
- Any architecture change that bypasses decision/version control.

## 15. Change Control

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
