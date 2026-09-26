# M21.1 — Structured Visual Project Contract v1.0

Status: DESIGN-READY
Phase: M21 — V1 Visual Pipeline Foundation
Source baseline: phase-1-3-foundation @ 51e5e48c6eceebdb3f31ce186a5264bfd443f457

## 1. Purpose

Define the canonical, deterministic input contract between PEYZAJ AI project truth and the visual rendering layer.

This contract does not authorize a renderer to change project geometry, planting decisions, quantities, terrain truth, or other design facts.

## 2. Authority boundary

PEYZAJ AI is authoritative for:
- project identity and lifecycle
- terrain/site geometry
- design/layout truth
- planting truth
- quantities and measurements
- render constraints

FLUX.2 is a visual representation provider only.

A render result MUST NOT be treated as authoritative project geometry or as a source for quantities.

## 3. Package

Canonical package:

```
PROJECT-ID/
├── project.json
├── terrain.json
├── site.json
├── layout.json
├── planting.json
├── quantities.json
├── render-instructions.json
├── site-plan.webp
└── references/
```

Source images MUST be preserved when required. WEBP is a transport/preview representation, not destructive source replacement.

## 4. Lifecycle

Allowed visual states:

NEW
→ COLLECTING
→ READY
→ VISUAL_PREPARED
→ RENDERING
→ RENDERED
→ WEBP_READY
→ DELIVERED

Blocking state:

BLOCKED_MISSING_REFERENCE

A blocked project cannot enter RENDERING.

## 5. Required project identity

```json
{
  "schema_version": "1.0",
  "project_id": "PROJECT-0017",
  "created_at": "ISO-8601",
  "source_commit": "git-sha",
  "units": "metric",
  "status": "READY"
}
```

## 6. Terrain truth

Required when terrain affects visual representation:

- site boundary geometry or explicit verified dimensions
- elevation data when grade/slope is material
- buildings and fixed structures
- roads/access
- existing relevant structures
- coordinate reference metadata where geographic coordinates are used

Unknown terrain values MUST remain unknown. They MUST NOT be fabricated by an LLM or renderer.

## 7. Site and layout truth

The layout contract represents deterministic project decisions, including where applicable:

- parcels
- buildings
- pedestrian areas
- vehicle/service areas
- parking/loading
- green zones
- buffers
- recreation
- hardscape
- lawn
- planting zones
- irrigation zones

Each geometry-bearing object SHOULD carry:
- stable id
- type
- geometry/reference
- dimensions/area where applicable
- source/provenance
- confidence/verification state

## 8. Planting truth

Planting records SHOULD contain:

- plant_id
- botanical_name
- common_name
- quantity
- spacing
- zone_id
- placement geometry/reference
- evidence reference
- verification status

Plant counts and spacing are deterministic outputs and MUST NOT be inferred from a final render.

## 9. Render instructions

Render instructions control visual representation only.

Minimum fields:

```json
{
  "schema_version": "1.0",
  "render_id": "RENDER-001",
  "input_project_id": "PROJECT-0017",
  "visual_intent": "photorealistic landscape visualization",
  "camera": {
    "mode": "reference_preserving",
    "view": "site_or_user_defined"
  },
  "preserve": [
    "site_boundary",
    "building_positions",
    "major_paths",
    "planting_zone_relationships"
  ],
  "do_not_invent": [
    "terrain_grade",
    "buildings",
    "roads",
    "plant_species",
    "site_extent"
  ],
  "provider": {
    "name": "FLUX.2",
    "model": "FLUX.2 Pro"
  },
  "output": {
    "format": "WEBP",
    "preserve_source": true
  }
}
```

## 10. Reference gate

Rendering MUST be blocked when a critical visual reference is absent.

Canonical reason:

`BLOCKED_MISSING_REFERENCE`

Examples:
- no usable site/layout representation
- missing required terrain reference
- missing required building/site reference
- unresolved geometry required by the requested camera/view

The system may request additional user input rather than inventing missing information.

## 11. Provider boundary

The visual provider receives a normalized render request derived from the project package.

The provider does not receive:
- unrestricted database access
- agent provisioning authority
- approval authority
- project mutation authority

The provider response is an artifact, not an authoritative state transition.

## 12. Deterministic validation

Before RENDERING, validate:

1. project_id exists
2. schema versions are compatible
3. required package members exist
4. source references resolve
5. critical geometry/reference requirements are satisfied
6. no prohibited/invented design instruction is present
7. output format is supported
8. provider/model is explicitly selected

Validation failure MUST prevent RENDERING.

## 13. Output contract

A successful provider response records:

- render_id
- project_id
- provider
- model
- request timestamp
- input artifact references/digests
- output artifact reference
- output MIME type
- dimensions
- provenance
- status

The visual result MUST be traceable back to the exact structured project inputs.

## 14. Non-goals

M21.1 does not implement:
- FLUX API calls
- image generation
- image-to-image execution
- WEBP conversion code
- Telegram delivery
- object storage
- model routing

Those belong to later M21 stages.

## 15. Acceptance criteria

M21.1 is ready for implementation when:

- the package structure is fixed
- lifecycle states are fixed
- authority boundaries are explicit
- missing-reference blocking is explicit
- render input/output provenance is explicit
- deterministic validation requirements are explicit
- FLUX is represented as a provider, not a design authority

Next stage: M21.2 — Site/Layout → Visual Input Adapter.
