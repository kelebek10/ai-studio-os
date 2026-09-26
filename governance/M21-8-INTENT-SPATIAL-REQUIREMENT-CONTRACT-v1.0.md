# M21-8 — INTENT → SPATIAL REQUIREMENT CONTRACT v1.0

**Status:** DESIGN BASELINE
**Authority:** PEYZAJ AI / PAI-FORGE Governance
**Purpose:** Customer natural-language intentini deterministik peyzaj tasarım girdisine dönüştüren sözleşme.

## 1. Core Principle
Customer language is not geometry.
The Intent Engine interprets what the customer wants. It does not invent coordinates, dimensions, plant species, geometry, or final placement.
Pipeline:
Customer request + existing-site evidence → Intent Engine → Spatial Requirement → Design Constraints → Deterministic Design Engine → authoritative layout.json → Draft Renderer → FLUX visual rendering.

## 2. Authority Boundaries
### Intent Engine MAY
- classify customer intent;
- extract target, purpose, experience, preferences and priorities;
- reference already identified site anchors;
- create structured spatial requirements;
- mark missing information explicitly.
### Intent Engine MUST NOT
- invent an anchor coordinate;
- infer exact dimensions from language alone;
- select unverified plant species;
- create authoritative geometry;
- directly call FLUX;
- override validated site measurements;
- silently convert uncertain observations into facts.
### Design Engine MAY
- resolve spatial placement using validated geometry;
- apply deterministic horticultural, circulation, visibility, sun, slope, drainage and safety rules;
- generate alternatives;
- produce traceable proposed geometry.
### Design Engine MUST
- consume only validated/approved inputs;
- distinguish hard constraints from soft preferences;
- preserve provenance from requirement to layout;
- fail closed when required information is missing.

## 3. Canonical Spatial Requirement
Minimum fields:
- requirement_id
- project_id
- intent_type
- source_text
- target
- anchor
- spatial_relation
- priority
- constraints
- required_evidence
- status
- provenance
Optional:
- view_direction
- preferred_zone
- experience_goal
- maintenance_preference
- privacy_requirement
- access_requirement

## 4. Controlled Intent Types
Initial production set:
- ENTRY_WELCOME
- BUTTERFLY_VIEW
- DRY_ROCK_GARDEN
- PRIVACY_SCREEN
- WINDOW_VIEW
- SEATING_AREA
- SHADE_AREA
- FRAGRANCE_ZONE
- LOW_MAINTENANCE
- CHILD_SAFE_AREA
- PET_AREA
New intent types require governance review; free-form intent types are not authoritative.

## 5. Controlled Anchors
- HOUSE_ENTRY
- WINDOW
- DOOR
- TERRACE
- PROPERTY_EDGE
- PATH
- DRIVEWAY
- USER_SELECTED_POINT
- EXISTING_ZONE
- REAR_GARDEN
- FRONT_GARDEN
An anchor is valid only when its identity and spatial reference are established by site evidence, project data or an explicit customer selection.
If an anchor cannot be established, status becomes NEEDS_INPUT or BLOCKED_MISSING_REFERENCE; no coordinate is invented.

## 6. Spatial Relations
- NEAR
- VISIBLE_FROM
- BETWEEN
- ALONG_PATH
- AROUND
- SCREEN
- BUFFER
- WITHIN_ZONE
- AWAY_FROM
- ADJACENT_TO

## 7. Constraint Classes
### Hard constraints
Must not be violated: validated property/building boundaries; access/circulation; safety exclusions; protected/existing fixed elements; validated measurements; explicit customer prohibitions.
### Soft constraints
Optimization preferences: aesthetic preference; focal emphasis; maintenance preference; desired atmosphere; seasonal effect; visual balance.
Hard constraints have precedence over soft constraints.

## 8. Priority
Controlled values: CRITICAL | HIGH | MEDIUM | LOW
Priority is not permission to violate a hard constraint.

## 9. Example Mappings
### Entry welcome
Customer: Eve girerken beni karşılayan güzel bir alan istiyorum.
Structured intent: intent_type ENTRY_WELCOME; anchor HOUSE_ENTRY; spatial_relation NEAR; experience_goal arrival experience; constraints entrance remains readable, circulation remains open, focal composition visible from approach.
### Butterfly view
Customer: Mutfak penceresinden baktığım yerde kelebekleri görmek istiyorum.
Structured intent: intent_type BUTTERFLY_VIEW; anchor identified WINDOW; spatial_relation VISIBLE_FROM; target BUTTERFLY_GARDEN; priority HIGH; constraints preserve view corridor, preserve access, use verified suitable species.
If the kitchen window is not identified, the system MUST request identification or additional evidence.
### Dry rock garden
Customer: Arka bahçeyi kuru/kaya bahçesi istiyorum.
Structured intent: intent_type DRY_ROCK_GARDEN; anchor/target REAR_GARDEN; spatial_relation WITHIN_ZONE; constraints evaluate sun, slope, drainage and soil before plant selection; apply verified regional plant rules.

## 10. Intent Confidence vs Validation
confidence describes interpretation confidence.
validation_status describes whether the spatial requirement is sufficiently evidenced.
High confidence MUST NOT promote an unverified anchor or geometry.

## 11. Missing Information
The system must fail closed.
Examples: Missing window identity → NEEDS_INPUT; Missing site extent → BLOCKED_MISSING_REFERENCE; Missing trusted measurement for measured-design requirement → NEEDS_MEASUREMENT; Conflicting evidence → NEEDS_REVIEW.
No silent assumptions.

## 12. Provenance
Every requirement must be traceable to customer message; source image/evidence when applicable; identified anchor; rule/constraint version; Design Engine decision; resulting layout element.
This enables auditability and later commercial support.

## 13. Acceptance Criteria
M21-8 is accepted only when:
1. Natural-language intent can be represented without losing source meaning.
2. No intent object contains invented authoritative geometry.
3. Unknown anchors remain unresolved.
4. Hard/soft constraints are explicit.
5. Design Engine receives deterministic structured requirements.
6. Requirement-to-layout provenance is preserved.
7. Missing evidence produces a controlled state.
8. Intent Engine cannot directly call the visual renderer or FLUX.
9. Controlled vocabulary prevents uncontrolled production semantics.
10. Test fixtures cover at least the three canonical examples above.

## 14. Non-Goals
This contract does not define final design algorithms; plant recommendation database; geometry optimization algorithms; SVG rendering; FLUX prompts; Telegram transport; commercial pricing.
Those are separate modules.

**Version:** 1.0
**Change policy:** Any field, controlled vocabulary, authority boundary or lifecycle change requires a new version and decision record.