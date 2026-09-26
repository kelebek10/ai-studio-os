# M21-15 — SCENE COMPOSITION CONTRACT v1.0

**Status:** DESIGN BASELINE

## Purpose
Create one canonical visual scene package from authoritative project layout and lighting layers. DAY, DUSK and NIGHT are presentation variants of the same design truth.

## Inputs
- validated `layout.json`
- validated `lighting.json` when applicable
- site/terrain references
- scene-specific environmental parameters
- approved render constraints

## Scene Types
- `DAY`
- `DUSK`
- `NIGHT`

## Invariants
Across all scenes:
1. parcel/site boundary is unchanged;
2. building and fixed geometry is unchanged;
3. hardscape geometry is unchanged;
4. planting/layout geometry is unchanged;
5. camera anchor remains tied to the same project geometry unless an explicit presentation variant is authorized;
6. lighting elements may change visibility/intensity by scene but may not change location;
7. no scene may invent design elements.

## Scene Modifiers
DAY: natural-light presentation; authoritative artificial-light elements are not visually active.
DUSK: reduced natural illumination; approved ambient/accent lighting becomes visible.
NIGHT: artificial lighting is the primary presentation layer; approved safety, entry, feature and ambiance lights are rendered according to their scene rules.

## Canonical Package
`scene_id`, `project_id`, `scene_type`, `layout_digest`, `lighting_digest`, `camera`, `environment`, `active_lighting_ids`, `render_constraints`, `provenance`, `status`.

## Authority Boundary
Scene composition prepares renderer/FLUX input. It cannot modify `layout.json` or `lighting.json`. FLUX output is an artifact, never project truth.

## Failure States
`BLOCKED_MISSING_REFERENCE | BLOCKED_LAYOUT_MISMATCH | BLOCKED_LIGHTING_MISMATCH | NEEDS_REVIEW | READY_FOR_RENDER`.

## Acceptance Criteria
- Three scenes generated from one layout.
- Layout digest identical across scenes.
- Lighting digest references the same lighting design; active IDs vary only by scene rules.
- No scene contains an element absent from authoritative inputs.
- Scene package is reproducible from identical inputs.

**Version:** 1.0
