# M21.6 — Photo Evidence Schema v1.0

## Status
DESIGN CONTRACT

## Purpose
Define the canonical evidence representation produced from customer garden photographs before any geometry is promoted into project truth.

## Authority
Photo evidence is observational input. It is not authoritative project geometry.

## Evidence Object
Each observation SHALL contain:
- observation_id
- project_id
- image_id
- observation_type
- image_region
- confidence
- evidence_status
- geometry_status
- source_provenance
- validation_status
- notes

## Observation Types
Initial controlled vocabulary:
- BUILDING
- WALL
- FENCE
- GATE
- TERRACE
- DECK
- PATH
- DRIVEWAY
- PARKING
- POOL
- WATER_FEATURE
- LAWN
- SOIL
- PLANTING_AREA
- TREE
- SHRUB
- HEDGE
- IRRIGATION_ELEMENT
- LIGHTING_ELEMENT
- FIXED_STRUCTURE
- ACCESS_POINT
- TEMPORARY_OBJECT
- UNKNOWN

## Evidence Status
- VISIBLE_CONFIRMED — directly visible in the image.
- INFERRED — interpretation derived from visual evidence and requiring validation.
- UNKNOWN — insufficient evidence.

## Geometry Status
- NONE
- IMAGE_REGION_ONLY
- APPROXIMATE
- VALIDATED

VALIDATED requires an external or deterministic validation source. Vision confidence alone cannot promote geometry to VALIDATED.

## Image Region
The observation SHALL retain a machine-readable image region, such as:
- bounding box
- polygon/mask when available
- normalized coordinates

The region is evidence provenance, not site coordinates.

## Spatial Relation
Optional relations may describe:
- adjacent_to
- inside
- connected_to
- aligned_with
- blocks_view_of
- access_to

Relations are hypotheses unless validated.

## Measurement Reference
When a known measurement is associated with an observation:
- measurement_id
- value
- unit
- reference_geometry
- source
- validation_status

No measurement may be inferred solely from visual appearance.

## Existing-Site Promotion
An observation can become part of the Existing Site Model only after:
1. provenance is preserved,
2. required geometry is available,
3. measurement requirements are satisfied,
4. validation status is explicit.

## Proposed Design Boundary
Photo evidence MUST NOT directly modify proposed layout.

The Design Engine consumes validated Existing Site Model data and produces the authoritative proposed layout.

## Privacy / Scope
Images and observations are project-scoped. They are not global training data, shared project data, or unrestricted database input.

## Acceptance Criteria
1. Every observation is traceable to an image.
2. Image regions are preserved.
3. Confidence is separate from validation.
4. Approximate geometry cannot silently become authoritative.
5. Existing and proposed states are separate.
6. The schema is provider-neutral.
7. The schema supports one or many photographs.
