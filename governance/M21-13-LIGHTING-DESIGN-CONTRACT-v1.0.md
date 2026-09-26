# M21-13 — LIGHTING DESIGN CONTRACT v1.0

**Status:** DESIGN BASELINE

## Purpose
Lighting is an authoritative design layer derived from validated site/layout truth. It is not a visual effect invented by the renderer or FLUX.

## Authority
Lighting Design MAY place conceptual/technical lighting elements only against validated layout/site anchors. It MUST NOT invent geometry or alter authoritative layout geometry.

## Controlled Types
- PATH_LIGHT
- STEP_LIGHT
- ENTRY_LIGHT
- UPLIGHT
- DOWNLIGHT
- WALL_WASH
- GRAZING_LIGHT
- TREE_LIGHT
- FEATURE_LIGHT
- TERRACE_LIGHT
- SECURITY_LIGHT

## Required Fields
`light_id`, `type`, `anchor_id`, `purpose`, `intensity_class`, `beam_direction`, `glare_control`, `source_requirement_ids`, `rule_version`, `validation_status`.

## Purposes
`CIRCULATION | ENTRY | FEATURE | AMBIANCE | SAFETY | SECURITY`

## Rules
1. Safety/circulation lighting has precedence over ambiance.
2. Glare control is mandatory for circulation and viewing contexts.
3. Lighting cannot obstruct access or conflict with fixed elements.
4. No exact photometric claim is made without a validated fixture specification.
5. FLUX may visualize lighting but cannot invent or relocate authoritative lighting elements.
6. Lighting remains traceable to layout/site requirements.

## Failure States
`BLOCKED_MISSING_REFERENCE | BLOCKED_CONFLICTING_CONSTRAINTS | NEEDS_FIXTURE_DATA | READY_FOR_RENDER`.

## Non-Goals
This contract does not define electrical load calculations, cable routing, fixture procurement, lux certification or final electrical engineering.

**Version:** 1.0
