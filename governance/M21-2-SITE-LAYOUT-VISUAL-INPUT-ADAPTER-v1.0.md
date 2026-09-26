# M21.2 — Site/Layout → Visual Input Adapter v1.0

Status: DESIGN-READY
Phase: M21 — V1 Visual Pipeline Foundation
Baseline: M21.1 @ d0cc58a1bbb30bcac061528097da12ff54baf116

## Purpose
Convert the validated PEYZAJ AI structured project package into a normalized visual-input package for a rendering provider.
The adapter is deterministic. It does not design, invent geometry, alter quantities, or infer missing terrain.

## Input
- project.json
- terrain.json when terrain is material
- site.json
- layout.json
- planting.json when planting is part of the requested view
- render-instructions.json
- usable site/layout visual reference
- optional quantities.json and additional reference images

## Output
Normalized VisualInput with: project_id, render_id, source_artifacts, geometry_constraints, visual_layers, planting_constraints, reference_images, camera, render_instructions, provider, provenance.

## Deterministic transformation
1. schema validation
2. artifact resolution
3. geometry normalization
4. unit normalization to metric
5. stable layer ordering
6. preservation of authoritative relationships
7. reference selection
8. render instruction normalization
9. provenance/digest generation

No semantic redesign is permitted.

## Geometry preservation
The adapter MUST preserve site boundary, building footprints, fixed structures, primary paths, vehicle/service access, hardscape zones, green zones, planting zones, irrigation zones when visually relevant, and verified terrain/slope constraints.
Coordinates and dimensions remain traceable to source artifacts.

## Planting transformation
Planting data becomes visual constraints, not free-form design instructions. Each constraint retains plant_id, botanical_name, zone_id, quantity, spacing, placement/reference, and verification state.
The adapter MUST NOT invent species, quantity, spacing, or placement.

## Reference selection
Priority: verified site/layout plan; verified terrain/site image; verified building/context image; approved style/reference image.
Style references affect visual appearance only and MUST NOT override project geometry.
If a required reference is missing, state = BLOCKED_MISSING_REFERENCE.

## Camera contract
Camera selection may use explicit user view, predefined project camera, or a deterministic default only when geometry is sufficient.
The adapter MUST NOT create a camera requiring unavailable geometry.

## Provider boundary
The output is provider-neutral except for explicit provider/model selection. The adapter does not call FLUX and does not possess provider credentials.

## Failure states
INVALID_PROJECT_SCHEMA; MISSING_REQUIRED_ARTIFACT; BLOCKED_MISSING_REFERENCE; INVALID_GEOMETRY; UNSUPPORTED_UNIT; INVALID_RENDER_INSTRUCTIONS; PROVIDER_NOT_SELECTED.
All failures are fail-closed.

## Provenance
Record source project id, source artifact identifiers, source artifact digests where available, adapter schema/version, creation timestamp, and provider/model target.

## Acceptance criteria
- every input has a validation rule
- every output field has a deterministic source
- missing references fail closed
- geometry cannot be changed by the adapter
- plant quantities/species cannot be invented
- provenance is complete
- no provider API call occurs inside the adapter

Next: M21.3 — FLUX.2 Pro API Adapter.