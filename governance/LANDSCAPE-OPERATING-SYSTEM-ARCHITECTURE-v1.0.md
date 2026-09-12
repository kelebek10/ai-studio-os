# PEYZAJ AI / PAI-FORGE — LANDSCAPE OPERATING SYSTEM ARCHITECTURE

**Document:** LANDSCAPE-OPERATING-SYSTEM-ARCHITECTURE-v1.0.md  
**Version:** 1.0  
**Status:** PROPOSED — ARCHITECTURAL BASELINE FOR CONTROLLED REVIEW  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`

## 1. Purpose

PAI-FORGE is not defined as a 3D landscape generator. The target system is a living Landscape Intelligence Operating System that can understand customer intent, evaluate environmental and scientific context, create an actionable design state, accept controlled revisions, learn from verified project outcomes, and continuously improve without allowing uncontrolled AI mutation of authoritative Core state.

3D is an output/rendering layer, not the system of record.

## 2. Core Principle

> **Understand → Contextualize → Decide → Compose → Validate → Apply → Observe → Learn → Improve**

The system must remain deterministic-first and evidence-grounded.

## 3. User Experience Boundary

The customer does not interact with catalog taxonomy, database schemas, assemblies, registries or internal decision structures.

The customer provides natural-language requests, location, photos, measurements, preferences, constraints and subsequent change requests.

The system converts these inputs into structured internal representations.

## 4. Target Architecture

```text
CUSTOMER
  ↓
Intent & Lifestyle Understanding
  ↓
Project Context
  ↓
Trusted Core
(Knowledge / Zone / Evidence / Catalog)
  ↓
Decision Engine
  ↓
Landscape Composition / Assembly
  ↓
Design State
  ↓
Validation + Impact Analysis
  ↓
Plan / Quantity / Cost / Application Inputs
  ↓
Geometry
  ↓
3D Renderer
  ↓
REAL PROJECT OUTCOME
  ↓
Feedback / Evidence / Failure Memory
  ↓
Controlled Learning Proposal
  ↓
Validation + Human Approval
  ↓
Trusted Core improvement
```

## 5. Major Internal Modules

1. **Customer Intent Engine** — converts natural language into structured intent, preferences, constraints and priorities.
2. **Lifestyle Scenario Model** — represents how the customer intends to use and experience the garden.
3. **Project Context Model** — location, site, environmental, spatial and existing-condition context.
4. **Decision Engine** — evaluates candidates against authoritative data, rules, constraints, evidence and customer intent.
5. **Landscape Composition / Assembly Engine** — composes materials, plants, structures and functional relationships into design solutions.
6. **Design State Engine** — authoritative representation of the current proposed project design.
7. **Change Request Engine** — converts customer revisions into controlled state changes.
8. **Impact / Dependency Engine** — identifies elements and decisions affected by a change; recalculates only affected scope where safe.
9. **Validation / Constraint Engine** — checks scientific, spatial, operational and project constraints before a state becomes approved.
10. **Project Memory** — preserves design versions, decisions, changes, outcomes and evidence.
11. **Failure Memory** — records verified failures, root causes, applicability and prevention constraints.
12. **Learning Proposal Engine** — turns verified project outcomes into candidate improvements; it cannot directly mutate authoritative Core state.
13. **Regression / Known-Failure Guard** — prevents a validated known failure from being reintroduced under equivalent conditions.
14. **Geometry / 3D Layer** — derives spatial geometry and visual output from an approved/selected Design State.

## 6. Design State

A Design State represents the current project solution at a specific version.

Conceptually it contains:

- project identity
- customer intent reference
- lifestyle scenario references
- site/context reference
- selected catalog/knowledge entities
- assemblies/components
- spatial relationships
- geometry references/parameters
- constraints
- decisions
- validation results
- version and lineage
- approval status

Design State is versioned. A customer change creates a new state/version; it does not silently overwrite history.

## 7. Change Request Model

A customer may request changes such as:

- move an olive tree one metre
- place colorful flowers along the kitchen-to-garden route
- move the veranda closer to the kitchen
- make a path more curved
- remove an element
- add a biological pool

Each request becomes a structured Change Request before mutation.

```text
Natural-language request
  ↓
Intent extraction
  ↓
Target identification
  ↓
Requested operation
  ↓
Impact analysis
  ↓
Constraint validation
  ↓
Candidate revised state
  ↓
Validation
  ↓
New Design State version
```

## 8. Impact and Dependency Rules

A change must not trigger unnecessary global redesign.

Example:

```text
Olive Tree
 ├── Tree-ring assembly
 ├── Decorative aggregate
 ├── Irrigation relation
 └── Nearby planting dependencies
```

Moving the tree may require recalculation of these dependencies but should not alter unrelated distant structures unless a validated dependency exists.

## 9. Lifestyle Scenarios

The system must model customer outcomes, not only requested objects.

Example:

> Swim and cool down in summer → rest beside the biological pool → drink coffee → eat at an outdoor table.

This may produce a composition containing:

- biological pool
- deck/veranda-like platform
- seating
- dining area
- shade
- access route
- planting
- lighting

The system therefore designs relationships between functions and experiences rather than merely placing catalog objects.

## 10. Catalog Role

Catalog is an internal decision resource, not a customer-facing product list.

Catalog Item answers **what it is**.

Use Case answers **what it can be used for**.

Zone Compatibility answers **where it is compatible**.

Assembly answers **what solution/composition it can participate in**.

Geometry answers **how a solution can be spatially formed**.

Project Instance answers **how it is actually used in this project**.

Commercial/manufacturer identity is not part of the authoritative landscape intelligence model unless a later procurement requirement explicitly requires it.

## 11. Learning Loop

PAI-FORGE must learn through controlled evidence, not autonomous self-modification.

```text
Project outcome
  ↓
Observation / feedback
  ↓
Candidate learning record
  ↓
Root-cause analysis
  ↓
Evidence verification
  ↓
Learning proposal
  ↓
Human/scientific review
  ↓
Approved rule / knowledge / constraint
  ↓
Regression test
  ↓
Core
```

## 12. Failure Memory — Never Repeat Known Failure

A verified failure must become reusable institutional memory.

A Failure Record should preserve:

- failure identity
- project/context conditions
- observed result
- root cause
- evidence
- affected decision chain
- prevention rule/constraint
- scope of applicability
- exceptions
- validation status
- approval history

The system must prevent a known validated failure from being proposed again under equivalent conditions, subject to explicit exception rules.

This is a design objective, not a claim of mathematical 100% prevention.

## 13. Authority Boundaries

- LLM output is a proposal, not authoritative truth.
- AI proposals cannot directly mutate authoritative Core state.
- Evidence is not knowledge.
- Project history is not automatically scientific truth.
- A field observation does not automatically become a universal rule.
- Learning proposals require controlled validation and approval.
- 3D output cannot become authoritative design truth merely because it looks plausible.

## 14. 3D Boundary

The 3D system consumes a selected/validated Design State and produces a visual representation.

```text
Design State
   ↓
Spatial/Geometry Derivation
   ↓
Scene Specification
   ↓
3D Renderer
```

The renderer must not invent authoritative plants, dimensions, materials or spatial decisions that are absent from the governing Design State.

## 15. Practicality Requirement

The system must be built incrementally.

### MVP sequence

1. Project Context
2. Customer Intent
3. Design State
4. Decision Engine foundation
5. Catalog/Knowledge integration
6. Change Request + Impact Analysis
7. Validation
8. Project Memory
9. Failure Memory + Regression Guard
10. Controlled Learning Loop
11. Geometry
12. 3D rendering

No speculative multi-agent architecture, knowledge graph, event-stream platform or autonomous self-modifying Core is required for the first implementation.

## 16. Non-Negotiable Rules

1. Core remains authoritative.
2. Structured-first → Semantic-second → LLM-last remains valid.
3. Customer-facing simplicity must hide internal complexity.
4. Design changes are versioned.
5. History is never silently overwritten.
6. Known verified failures become regression constraints.
7. Learning is controlled, not autonomous mutation.
8. 3D is downstream from design decisions.
9. Every new module must have a clear authority boundary.
10. No module is created merely because it is technically possible.

## 17. Relationship to Existing Governance

This document extends the existing PAI-FORGE governance model; it does not replace Identity, Zone, Evidence, Registry, PostgreSQL or Core security controls.

The existing rule remains:

> **Kesinleşmeyen karar GitHub'a yazılmaz; kesinleşen karar GitHub'da kayıt altına alınır.**

This document is therefore **PROPOSED** until reviewed against the current governance baseline and dependency order.

## 18. Next Controlled Review

The next review must determine:

- which modules belong in Core vs application/service layers
- Design State identity/version semantics
- Change Request and idempotency semantics
- dependency graph authority
- Project Memory vs Evidence boundary
- Failure Memory vs Knowledge boundary
- Learning Proposal approval lifecycle
- regression-test storage and execution boundary
- interaction with Identity and Zone models
- PostgreSQL schema implications

No production implementation is authorized by this document.
