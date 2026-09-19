# PEYZAJ AI / PAI-FORGE — INTENT TO DECISION CONTRACT

**Document:** INTENT-TO-DECISION-CONTRACT-v1.0.md  
**Version:** 1.0  
**Status:** PROPOSED — CONTROLLED ARCHITECTURAL CONTRACT  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`

## 1. Purpose

This contract defines the boundary between customer intent interpretation and the PAI-FORGE Decision Engine.

The contract prevents natural-language interpretation, LLM output or customer preference from becoming an authoritative design decision without contextual and scientific validation.

## 2. Governing Principle

> **Intent describes what the customer wants. Decision determines what is feasible, suitable and defensible.**

Intent is therefore a decision input, never a decision authority.

## 3. Flow

```text
Customer Request
      ↓
Intent Extraction
      ↓
Structured Intent
      ↓
Project Context
      ↓
Trusted Core
(Knowledge / Zone / Evidence / Catalog)
      ↓
Deterministic Rules / Scientific Models
      ↓
Decision Engine
      ↓
Candidate Design Decision
      ↓
Validation / Constraints
      ↓
Design State
```

The established principle remains:

**Structured-first → Semantic-second → LLM-last.**

## 4. Required Input Contract

Decision Engine input must distinguish at least:

```text
intent
project_context
site_constraints
zone_context
trusted_knowledge_refs
evidence_refs
catalog_refs
lifestyle_context
existing_design_state
applicable_rules
known_failure_constraints
```

Not every field is mandatory for every request, but missing critical information must be explicit.

## 5. Decision Responsibilities

Decision Engine is responsible for:

- evaluating intent against project context;
- resolving compatible Knowledge/Catalog candidates;
- applying deterministic rules and scientific models;
- checking Zone compatibility;
- checking known validated failure constraints;
- identifying conflicts;
- identifying missing data;
- producing candidate decisions with rationale and provenance;
- returning validation status and uncertainty.

It must not treat an LLM-generated candidate as authoritative merely because it is plausible.

## 6. Intent-to-Decision Mapping

Example A — drought-tolerant garden:

```text
Intent:
  WATER_EFFICIENCY
  DROUGHT_TOLERANT_DESIGN

Decision inputs:
  climate
  water availability
  soil
  sun exposure
  irrigation constraints
  maintenance capacity
  existing planting
  Zone compatibility
  validated plant knowledge

Decision output:
  feasible low-water design candidates
```

Example B — butterfly area:

```text
Intent:
  POLLINATOR_SUPPORT
  target = BUTTERFLIES
  spatial_target = GARDEN_SUBSECTION

Decision inputs:
  climate
  Zone
  soil
  sun
  water
  host/nectar plant knowledge
  bloom/season continuity
  maintenance
  pesticide constraints
  existing planting

Decision output:
  habitat-supporting design candidate(s)
```

The output must not promise the ecological outcome with certainty.

## 7. NO-DATA Rule

If a critical input is unavailable or contradictory, Decision Engine must not silently infer authoritative facts.

Allowed outcomes:

- request targeted clarification;
- continue with explicit assumptions when risk is acceptable;
- return `NO-DATA`;
- return `CONFLICT_REQUIRES_REVIEW`;
- return a bounded candidate with explicit uncertainty.

## 8. Known-Failure Guard

Before finalizing a candidate decision, the system must check applicable validated Failure Memory / regression constraints.

A candidate that reproduces a known validated failure under equivalent conditions must be blocked or explicitly routed to controlled exception review.

Failure Memory is not automatically scientific truth; its scope and approval status must be respected.

## 9. Evidence Boundary

The Decision Engine may consume approved evidence references, but:

- evidence is not itself a decision;
- project history is not automatically scientific truth;
- an observation is not automatically a universal rule;
- conflicting evidence must remain visible;
- unsupported LLM claims cannot satisfy an evidence requirement.

## 10. LLM Boundary

LLMs may assist with:

- intent extraction;
- semantic interpretation;
- candidate generation;
- explanation;
- controlled orchestration.

LLMs may not directly:

- mutate Core;
- approve scientific knowledge;
- bypass Zone/Identity constraints;
- override deterministic calculations;
- suppress uncertainty;
- convert an assumption into a fact;
- approve their own proposal.

## 11. Decision Output Contract

A candidate decision should preserve:

```text
decision_id
intent_ref
project_context_ref
candidate_solution
supporting_knowledge_refs
evidence_refs
rules_applied
constraints_checked
known_failure_checks
assumptions
uncertainties
conflicts
validation_status
provenance
model/procedure versions
```

The decision becomes part of Design State only through the controlled Design State workflow.

## 12. Customer Language vs Internal Vocabulary

The customer may say:

> “Bahçem fazla su istemesin ama yazın da güzel görünsün.”

The customer must not need to know `WATER_EFFICIENCY`, `DROUGHT_TOLERANT_DESIGN` or any registry code.

Natural language is the external interface. Canonical vocabulary is an internal contract.

## 13. Multiple Intents

A single request may contain multiple goals.

Example:

> “Kelebekler gelsin, az su harcayayım ve mutfaktan çıkınca renkli çiçekler göreyim.”

Possible structured intent set:

```text
POLLINATOR_SUPPORT
WATER_EFFICIENCY
ARRIVAL_EXPERIENCE
SEASONAL_COLOR
```

Decision Engine must resolve interactions and conflicts rather than processing each intent independently and blindly combining results.

## 14. Priority and Trade-offs

Customer priority is an input, not an automatic override.

When goals conflict, the Decision Engine must expose the trade-off.

Example:

```text
maximum butterfly habitat
vs.
minimum irrigation
vs.
minimum maintenance
```

No single goal should silently dominate unless an approved rule or explicit customer priority establishes that hierarchy.

## 15. Approval Boundary

The Decision Engine produces candidate decisions.

Controlled workflow determines whether the candidate becomes part of an approved Design State.

No AI proposal directly becomes authoritative Core state.

## 16. Non-Goals

This contract does not define:

- complete Decision Engine algorithms;
- plant suitability scoring formulas;
- irrigation equations;
- full Design State schema;
- Change Request schema;
- final PostgreSQL implementation;
- autonomous learning;
- autonomous approval.

Those require separate controlled contracts.

## 17. Quality Gates

The Intent → Decision boundary passes only if:

1. customer intent is preserved;
2. intent interpretation is separated from scientific validation;
3. Project Context is explicit;
4. critical missing data cannot be silently fabricated;
5. Zone/Identity/Knowledge constraints remain authoritative;
6. known validated failures are checked;
7. evidence and provenance are traceable;
8. LLM proposals remain non-authoritative;
9. uncertainty and conflicts remain visible;
10. final decisions enter Design State through controlled versioning.

## 18. Status

**PROPOSED — CONTROLLED ARCHITECTURAL CONTRACT.**

Implementation remains blocked until this contract is reconciled with Design State, Change Request, Identity, Zone, Knowledge, Evidence and PostgreSQL governance and receives the required review/approval.
