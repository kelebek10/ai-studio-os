# M21-9 — DETERMINISTIC DESIGN ENGINE CONTRACT v1.0

**Status:** DESIGN BASELINE
**Authority:** PEYZAJ AI / PAI-FORGE Governance
**Purpose:** Validated spatial requirements, site truth, terrain and verified landscape rules from deterministic design output üretmek.

## 1. Core Principle
The Design Engine converts structured requirements into traceable proposed spatial design. It is the first layer allowed to make placement decisions, but it is not allowed to invent site truth.

Pipeline:
Spatial Requirement + Existing Site Model + Terrain + Verified Plant Data + Design Rules
→ Candidate Zones → Constraint Resolution → Spatial Placement → Planting/Hardscape Allocation → authoritative layout.json

## 2. Inputs
Required:
- validated project/site identity;
- validated site boundary and fixed elements;
- applicable terrain/topography data or explicit terrain-unknown state;
- validated spatial requirements;
- applicable design-rule version;
- verified plant/material data when planting/material selection is required.

Optional:
- customer preferences;
- maintenance target;
- seasonal objectives;
- visual priorities;
- existing planting evidence.

## 3. Authority Boundary
The Design Engine MAY:
- generate candidate zones;
- score candidate locations against explicit rules;
- resolve compatible hard and soft constraints;
- allocate spatial functions;
- select only verified plant/material candidates;
- generate alternatives when permitted;
- produce deterministic geometry proposals;
- attach provenance and rule references.

The Design Engine MUST NOT:
- invent parcel or building geometry;
- convert uncertain photo observations into validated geometry;
- use unverified species as authoritative recommendations;
- silently ignore hard constraints;
- treat FLUX output as design truth;
- directly modify source evidence;
- bypass measurement gates;
- create geometry outside the authoritative project coordinate system.

## 4. Constraint Resolution
Resolution order:
1. Site boundary
2. Fixed/protected elements
3. Safety and access
4. Validated measurements
5. Explicit customer prohibitions
6. Functional requirements
7. Horticultural/environmental rules
8. Maintenance constraints
9. Aesthetic preferences
10. Secondary optimization preferences

Hard constraints are non-negotiable. Soft constraints may be traded only when the trade-off is recorded.

## 5. Candidate Zone Generation
For each spatial requirement the engine must:
1. identify eligible source zones;
2. exclude prohibited areas;
3. apply required spatial relations;
4. evaluate access and circulation;
5. evaluate environmental suitability;
6. create candidate geometry;
7. retain the rule/evidence references that produced the candidate.

No candidate is authoritative until validation succeeds.

## 6. Placement Model
Every proposed element should carry:
- element_id
- function_type
- geometry
- geometry_status
- source_requirement_ids
- constraint_results
- rule_version
- evidence_refs
- confidence
- validation_status

Geometry status must distinguish at minimum:
`PROPOSED | VALIDATED | BLOCKED`.

Confidence does not replace validation.

## 7. Canonical Design Functions
Initial controlled functions:
- ENTRY_COMPOSITION
- BUTTERFLY_GARDEN
- DRY_ROCK_GARDEN
- PRIVACY_SCREEN
- VIEW_CORRIDOR
- SEATING_ZONE
- SHADE_ZONE
- FRAGRANCE_ZONE
- CHILD_SAFE_ZONE
- PET_ZONE
- LOW_MAINTENANCE_ZONE

Additional functions require governance review.

## 8. Canonical Example — Entry Welcome
Requirement: ENTRY_WELCOME near HOUSE_ENTRY.
Rules:
- preserve entry access;
- maintain readable arrival path;
- do not obstruct doors/gates;
- create a focal composition within eligible area;
- preserve required circulation clearance;
- use only verified plant/material candidates.
Output is a spatial composition, not a FLUX prompt.

## 9. Canonical Example — Butterfly View
Requirement: BUTTERFLY_VIEW visible from identified kitchen WINDOW.
Rules:
- window anchor must be validated;
- derive or validate view direction;
- preserve a view corridor between window and target area;
- target must lie within an eligible planting zone;
- evaluate sun, drainage, soil and regional suitability;
- select only verified butterfly-supporting species;
- preserve access for maintenance.
If window identity or view direction cannot be established, the requirement remains unresolved.

## 10. Canonical Example — Dry Rock Garden
Requirement: DRY_ROCK_GARDEN within REAR_GARDEN.
Rules:
- rear-garden extent must be known;
- evaluate slope and drainage;
- identify suitable exposure;
- reserve circulation/access;
- allocate rock/gravel/hardscape areas;
- select only verified drought/suitability candidates;
- do not infer soil properties without evidence.

## 11. Alternatives
The engine may produce multiple candidates when more than one solution satisfies hard constraints.
Each alternative must include:
- alternative_id;
- satisfied requirements;
- unresolved/relaxed soft preferences;
- rule references;
- geometry;
- validation state.

Alternatives are not ranked by hidden model preference. Ranking criteria must be explicit and deterministic.

## 12. Failure States
Controlled states:
- BLOCKED_MISSING_REFERENCE
- BLOCKED_MISSING_MEASUREMENT
- BLOCKED_CONFLICTING_CONSTRAINTS
- BLOCKED_NO_ELIGIBLE_ZONE
- NEEDS_REVIEW
- READY_FOR_RENDER

No silent fallback is permitted.

## 13. Provenance
Every layout element must be traceable:
customer request → spatial requirement → design rule → candidate zone → placement decision → layout element.

Plant/material selections must additionally reference the verified data record used.

## 14. Determinism
For identical authoritative inputs and identical rule/data versions, the engine must produce the same result or the same explicitly ordered alternative set.
Randomness is prohibited in authoritative placement unless a versioned deterministic seed and reproducibility contract are introduced.

## 15. Separation from Renderer and FLUX
Renderer converts authoritative layout geometry into technical visual representation.
FLUX converts approved visual input into a photorealistic representation.
Neither renderer nor FLUX may modify authoritative design geometry.

## 16. Acceptance Criteria
M21-9 is accepted only when:
1. Design Engine consumes structured requirements rather than raw customer language.
2. Site truth is never invented.
3. Hard constraints are never silently violated.
4. Candidate zones are traceable.
5. Placement decisions are reproducible.
6. Plant/material choices reference verified records.
7. Unresolved requirements fail closed.
8. Every layout element has provenance.
9. Renderer and FLUX remain downstream consumers.
10. The three canonical examples can be represented as deterministic design fixtures.

## 17. Non-Goals
This contract does not define implementation language, optimization library, database schema, SVG renderer, FLUX prompt format, Telegram transport, pricing or UI.

**Version:** 1.0
**Change policy:** Changes to authority boundaries, constraint precedence, controlled functions, placement semantics or failure states require a new version and decision record.