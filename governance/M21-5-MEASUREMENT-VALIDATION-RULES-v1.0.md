# M21.5 — Measurement Validation Rules v1.0

## Status
DESIGN CONTRACT

## Purpose
Define when photo-derived observations can become usable geometric constraints for PEYZAJ AI.

## Rule 1 — No Scale by Appearance
Perspective, camera metadata, object familiarity, or visual intuition alone cannot establish exact dimensions.

## Rule 2 — Measurement Sources
Accepted scale sources, in descending evidentiary strength:
1. verified site/architectural plan
2. customer-provided measured dimension
3. trusted survey/GIS geometry
4. deterministic reconstruction using multiple images plus validated reference dimensions
5. single-photo visual estimate — concept only, never authoritative scale

## Rule 3 — Reference Dimension
A reference measurement must identify:
- reference_id
- dimension_value
- unit
- measured object/segment
- source
- validation status

## Rule 4 — Geometry Promotion
Candidate geometry may be promoted to authoritative geometry only when:
- its source is traceable,
- required dimensions are validated,
- geometry is internally consistent,
- uncertainty is within the applicable project tolerance,
- validation status is explicit.

## Rule 5 — Single Photo
Single-photo input can produce:
- visible-object inventory,
- approximate relative arrangement,
- concept-level layout,
- visual render constraints.

Single-photo input cannot produce:
- exact site dimensions,
- exact area,
- survey-grade boundaries,
- reliable quantities,
- project-grade construction geometry.

## Rule 6 — Multiple Photos
Multiple photographs may improve spatial reconstruction but do not automatically create scale. At least one validated scale reference remains required for measured design.

## Rule 7 — User Interaction
When scale is insufficient, the system should request the smallest useful measurement, for example:
- garden width
- garden length
- terrace width
- building facade width
- path width

The system should not ask for a complete survey when one reference dimension is sufficient.

## Rule 8 — Confidence
Geometry carries:
- confidence
- evidence_status
- measurement_source
- validation_status

Confidence is not a substitute for measurement.

## Rule 9 — Tolerance
Project-grade geometry must declare an applicable tolerance. Tolerance values are domain/configuration parameters and must not be invented by the vision model.

## Rule 10 — Fail Closed
If required scale or geometry validation is missing:
- concept path may continue where safe,
- measured-design path stops,
- state becomes NEEDS_MEASUREMENT or BLOCKED_MISSING_REFERENCE as appropriate.

## Acceptance Criteria
1. No visual estimate becomes exact geometry without a valid scale source.
2. Customer measurement can be attached to a specific geometric reference.
3. Multiple photos improve evidence but do not bypass scale validation.
4. Measured-design readiness is deterministic.
5. Every promoted dimension has provenance.
6. Uncertainty is never silently discarded.
7. The rule set is independent of any particular vision or rendering provider.
