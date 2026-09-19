# PEYZAJ AI / PAI-FORGE — INTENT MODEL

**Document:** INTENT-MODEL-v1.0.md  
**Version:** 1.0  
**Status:** PROPOSED — CONTROLLED ARCHITECTURAL CONTRACT  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`

## 1. Purpose

Intent Model converts customer natural-language requests into a structured representation of what the customer is trying to achieve. It is an interpretation contract, not a decision authority.

The system must understand varied language without requiring the customer to know landscape terminology.

Examples:

- “Su çok harcamak istemiyorum.”
- “Az sulama isteyen bir bahçe istiyorum.”
- “Kurakçıl bir bahçe yapalım.”

may map to a common intent family such as `WATER_EFFICIENCY / DROUGHT_TOLERANT_DESIGN`.

Likewise:

- “Kelebekler gelsin.”
- “Bahçenin bir köşesinde kelebek alanı istiyorum.”
- “Sabah kahvemi içerken kelebekleri görmek istiyorum.”

may express `POLLINATOR_SUPPORT`, while also carrying a lifestyle and spatial objective.

## 2. Authority Boundary

Intent is customer meaning, not scientific truth and not a design decision.

- Intent Engine may interpret and structure.
- Intent Engine may preserve ambiguity.
- Intent Engine may assign confidence and assumptions.
- Intent Engine must not invent site facts.
- Intent Engine must not approve knowledge.
- Intent Engine must not select authoritative plants/materials by itself.
- Intent Engine must not mutate Core.
- Decision Engine remains responsible for evaluating feasible design solutions.

## 3. Canonical Intent Structure

A normalized Intent should contain, where applicable:

```text
intent_id
project_id
source_request_id
primary_intent
secondary_intents[]
goals[]
preferences[]
constraints[]
spatial_target
lifestyle_scenario_refs[]
environmental_requirements[]
priority
confidence
assumptions[]
ambiguities[]
requested_outcome
source_text
parser_model
parser_model_version
created_at
status
```

`intent_id` identifies the intent record; it is not a substitute for Entity, Knowledge, Zone, Design State or Change Request identity.

## 4. Intent Categories

Initial vocabulary is extensible and must not become a hard-coded list that prevents natural language understanding.

Examples include:

- `WATER_EFFICIENCY`
- `DROUGHT_TOLERANT_DESIGN`
- `POLLINATOR_SUPPORT`
- `BUTTERFLY_HABITAT`
- `PRIVACY`
- `SHADE`
- `COOLING`
- `LOW_MAINTENANCE`
- `ARRIVAL_EXPERIENCE`
- `ENTERTAINING`
- `NIGHT_USE`
- `CHILD_FRIENDLY`
- `PET_FRIENDLY`
- `EDIBLE_GARDEN`
- `SEASONAL_COLOR`

These are semantic candidates, not automatically approved scientific or registry vocabulary.

## 5. Intent vs Outcome

The system must distinguish what the customer requests from what the system can scientifically support.

Example:

> “Kelebekleri çeken bir bahçe istiyorum.”

Customer intent: provide conditions favorable to butterflies.

It does **not** mean:

> “Butterflies will definitely appear.”

The Decision/Validation layers must determine suitability and communicate uncertainty where necessary.

## 6. Spatial Intent

Intent may identify a spatial target without knowing its final geometry.

Examples:

- whole garden
- garden subsection
- kitchen exit
- pool edge
- entrance route
- existing olive tree vicinity
- shaded seating area

Spatial target may be unresolved until Project Context and Design State provide sufficient information.

## 7. Lifestyle Intent

An intent can reference a desired experience rather than an object.

Example:

> “Akşam yemek yerken bahçeyi de yaşayabileceğim bir alan istiyorum.”

This may imply dining, lighting, circulation, shade/privacy, views and planting relationships. The system must not prematurely reduce this to a single catalog item.

## 8. Ambiguity and Missing Data

Intent extraction must preserve uncertainty.

If the request is ambiguous, the system may:

1. ask a targeted clarification;
2. continue with explicit assumptions when risk is low;
3. return `NO-DATA` / unresolved intent when a safe decision cannot be made.

The LLM must never silently convert missing site data into facts.

## 9. Confidence

Confidence describes interpretation confidence, not scientific correctness.

High confidence in interpreting “az sulama isteyen bahçe” does not mean the proposed design is scientifically valid. Scientific and operational validation occurs downstream.

## 10. Versioning and Lineage

Intent records must preserve:

- original customer wording;
- normalized interpretation;
- parser/model/version provenance;
- assumptions and ambiguities;
- subsequent corrections;
- relationship to Design State and Change Request versions.

Historical intent must not be silently overwritten.

## 11. Change Requests

A customer revision is first interpreted as Intent and then transformed into a Change Request when an actionable state mutation is required.

Example:

`“Zeytini bir metre sağa al.”`

Intent interpretation → target olive + MOVE operation + one metre + direction/right.

The Change Request layer then performs target resolution, dependency analysis, validation and versioned Design State mutation.

## 12. Non-Goals

Intent Model v1.0 does not define:

- plant selection algorithms;
- scientific suitability rules;
- irrigation calculations;
- geometry generation;
- 3D rendering;
- autonomous design approval;
- Core mutation;
- autonomous learning;
- final registry vocabulary governance.

## 13. Quality Gates

An Intent is acceptable for downstream processing only when:

- source request is preserved;
- primary intent is structurally identifiable or explicitly unresolved;
- ambiguity is preserved rather than guessed away;
- confidence is separated from scientific validity;
- assumptions are explicit;
- provenance is preserved;
- no authoritative Core mutation occurs at extraction time.

## 14. Architectural Position

```text
Customer Natural Language
        ↓
Intent Extraction
        ↓
Structured Intent
        ↓
Project Context + Lifestyle Context
        ↓
Decision Engine
```

Intent is therefore an input to decision-making, not the decision itself.

## 15. Status

**PROPOSED — CONTROLLED ARCHITECTURAL CONTRACT.**

Implementation is not authorized solely by this document. It must be reconciled with Design State, Change Request, Identity, Zone, Knowledge, Evidence and PostgreSQL governance before implementation.
