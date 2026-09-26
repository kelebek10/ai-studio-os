# M21.7 — Measurement Validation Decision Tree v1.0

## Status
DESIGN CONTRACT

## Objective
Deterministically decide whether a customer garden input is ready for concept visualization or measured design.

## Decision Flow

PHOTO RECEIVED
-> Image quality sufficient?
  NO -> NEEDS_PHOTO
  YES
-> Fixed-site elements sufficiently visible?
  NO -> NEEDS_ADDITIONAL_ANGLE
  YES
-> Trusted geometry/site plan available?
  YES -> validate against source -> proceed
  NO
-> Customer supplied at least one usable reference measurement?
  NO -> READY_FOR_CONCEPT + NEEDS_MEASUREMENT for measured-design path
  YES
-> Reference measurement identifies a visible geometric segment?
  NO -> NEEDS_MEASUREMENT
  YES
-> Geometry reconstructed consistently with reference?
  NO -> NEEDS_ADDITIONAL_ANGLE or NEEDS_MEASUREMENT
  YES
-> Required project elements have sufficient evidence?
  NO -> BLOCKED_MISSING_REFERENCE
  YES -> READY_FOR_MEASURED_DESIGN

## Minimum Measurement Strategy
Ask for the smallest useful measurement rather than demanding a complete survey.

Examples:
- garden width
- garden length
- building facade width
- terrace width
- known path width

The selected reference must be visibly identifiable in the supplied image.

## Two Output Classes

### Concept Ready
Permits:
- approximate existing-site representation
- conceptual layout
- visual style exploration
- FLUX visualization with explicit uncertainty

Does not permit:
- construction-grade geometry
- exact quantities
- exact cost calculation based on inferred dimensions

### Measured Design Ready
Permits:
- authoritative layout generation
- deterministic quantities
- area calculations
- cost calculations when pricing inputs exist
- project-grade visual preparation

Requires:
- validated scale
- sufficient fixed geometry
- provenance for promoted measurements
- no unresolved blocking evidence

## Fail-Closed Rules
- Never invent missing dimensions.
- Never convert confidence into measurement.
- Never treat a single photograph as survey geometry.
- Never allow FLUX output to establish measurements.
- Never derive authoritative quantities from a render.

## Acceptance Criteria
1. Same evidence state produces the same readiness state.
2. Concept and measured-design paths are explicitly separated.
3. Missing measurements create an actionable request.
4. Blocking evidence cannot be bypassed by the rendering provider.
5. Every measured geometry element has provenance.
