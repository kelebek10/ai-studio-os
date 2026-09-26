# M21.4 — Photo Site Understanding Pipeline v1.0

## Status
DESIGN CONTRACT

## Purpose
Define how a customer's real garden photographs become controlled existing-site evidence without allowing vision models to invent geometry, dimensions, plants, or quantities.

## Core Principle
A photograph is evidence of visible appearance, not authoritative project geometry.

Pipeline:
PHOTO INPUT -> IMAGE QUALITY CHECK -> VISION SITE UNDERSTANDING -> EVIDENCE OBJECTS -> MEASUREMENT/CONFIDENCE GATE -> EXISTING-SITE MODEL -> DESIGN INPUT

## 1. Input
- One or more customer garden photographs.
- Optional known dimensions supplied by the customer.
- Optional site plan, parcel/building plan, additional reference images.
- Optional GPS/location metadata only when explicitly provided/authorized.

## 2. Image Quality Gate
Each image receives:
- image_id
- orientation
- resolution
- blur/occlusion assessment
- usable_area estimate
- visibility of ground plane
- visibility of fixed structures
- perspective severity
- quality_status

Insufficient evidence must not be silently converted into geometry.

## 3. Vision Site Understanding
Vision processing may identify visible candidates:
- building/facade
- wall/fence
- terrace/deck
- pavement/path
- driveway/parking
- pool/water feature
- lawn/soil/planting area
- visible trees/shrubs
- irrigation-visible elements
- furniture/temporary objects
- entrances/access points
- shadows/occlusions

Every observation carries:
- observation_id
- class
- image_id
- image_region
- confidence
- evidence_status
- geometry_status
- source provenance

## 4. Evidence Classes
VISIBLE_CONFIRMED: directly visible.
INFERRED: model-derived interpretation requiring validation.
UNKNOWN: insufficient evidence.

INFERRED and UNKNOWN data cannot become authoritative geometry without validation.

## 5. Geometry Rule
Vision may propose approximate geometry only as candidate evidence.
Authoritative geometry requires:
- customer measurement, or
- trusted site/plan source, or
- deterministic reconstruction with sufficient validated reference measurements.

No single photograph may establish exact scale by itself.

## 6. Existing-Site Model
The system creates a separate existing-site representation before design:
- existing boundaries when verified
- fixed structures
- circulation
- existing hardscape
- existing vegetation candidates
- visible terrain/slope evidence
- measurement references
- confidence/provenance

Existing-site model is distinct from proposed layout.

## 7. Design Boundary
Vision cannot:
- select final plant quantities
- invent dimensions
- move existing buildings
- establish exact property boundaries from appearance alone
- declare hidden areas
- replace customer measurements
- generate final quantities

The deterministic Design Engine consumes validated existing-site data and produces layout.json.

## 8. Missing Evidence
States:
- NEEDS_PHOTO
- NEEDS_ADDITIONAL_ANGLE
- NEEDS_MEASUREMENT
- NEEDS_SITE_PLAN
- READY_FOR_CONCEPT
- READY_FOR_MEASURED_DESIGN
- BLOCKED_MISSING_REFERENCE

## 9. Concept vs Measured Design
READY_FOR_CONCEPT permits visual concept generation with explicit uncertainty.
READY_FOR_MEASURED_DESIGN requires sufficient validated scale/geometry evidence.

The UI must visibly distinguish concept output from measured/project-grade output.

## 10. Provenance
Every extracted observation must retain image_id and region/reference information.
Every promoted geometry element must retain its validation source.

## 11. Security
Customer photographs are project-scoped inputs. No unrestricted model access to the project database. Vision output enters through a controlled adapter and validation layer.

## 12. Acceptance Criteria
1. No photograph is treated as authoritative geometry by default.
2. Every observation has provenance.
3. Confidence/evidence state is retained.
4. Missing scale produces a measurement gate rather than fabricated dimensions.
5. Existing-site model is separate from proposed design.
6. Concept and measured-design readiness are distinguishable.
7. Final layout remains deterministic and authoritative outside the vision model.
8. No direct FLUX call occurs in this stage.
