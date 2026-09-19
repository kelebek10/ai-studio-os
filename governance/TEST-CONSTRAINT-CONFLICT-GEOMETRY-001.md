# PEYZAJ AI / PAI-FORGE — CONSTRAINT / CONFLICT GEOMETRY TEST

**Test:** Constraint / Conflict Geometry 001  
**Date:** 2026-09-13  
**Branch:** `phase-1-3-foundation`  
**Status:** PASS — REQUIRED HARDENING CONFIRMED  
**Classification:** Controlled Test Record  

## 1. Customer Request

> “Zeytini 1 metre sağa al, kelebek alanını bozma, ama mutfaktan görünürlüğü de koru.”

## 2. Test Fixture

This is synthetic geometry for architecture testing only; it is not real project data.

Coordinate system: metres.

- Kitchen observation point: `K = (0,0)`
- Olive initial centre: `O1 = (4,4)`
- Olive crown/impact radius: `r = 0.75 m`
- Butterfly protected area: rectangle `x=5..9, y=2..6`
- Primary kitchen viewing target: `V = (8,8)`
- Kitchen visibility corridor: sightline from `K` toward `V` (`y=x`), with a protected visual corridor around it.

Requested target position:

- `O2 = (5,4)` = exactly 1 m right.

## 3. Step-by-Step Execution

### Step 1 — Intent / Change Parsing

Action:
- target = olive
- operation = MOVE
- delta = +1.0 m X direction

Explicit preservation constraints:
- `C1` = butterfly area must not be functionally/physically degraded
- `C2` = kitchen visibility must remain acceptable

The preservation statements are constraints, not optional preferences.

### Step 2 — Dependency Set

Olive movement affects:

- tree ring
- irrigation relation
- nearby planting spacing
- butterfly-area spatial relationship
- kitchen sightline relationship

Unrelated project components are excluded from recalculation.

### Step 3 — Geometry Check

At `O2=(5,4)`, the olive impact radius extends into the protected butterfly rectangle beginning at `x=5`.

Result:

- `C1 Butterfly Area`: **FAIL**
- `C2 Kitchen Visibility`: **PASS** for this synthetic fixture; the move shifts the olive away from the `y=x` sightline rather than creating a new obstruction.

### Step 4 — Decision Gate

Because `C1` fails, the system must NOT:

- shrink the butterfly area automatically;
- move the butterfly area automatically;
- reduce the requested 1 m movement silently;
- declare the design successful because visibility passed;
- optimize for aesthetics and hide the conflict.

The requested state is therefore **UNSATISFIABLE under the current geometry and explicit constraints**.

### Step 5 — Alternatives

The system may present controlled alternatives, for example:

1. keep the olive in place;
2. move the olive in another direction;
3. move it less than 1 m;
4. redesign the butterfly-area boundary with explicit customer approval;
5. change the visibility requirement with explicit customer approval.

No alternative is applied automatically when it sacrifices an explicit customer constraint.

## 4. Test Result

**PASS — REQUIRED HARDENING CONFIRMED.**

The test demonstrates that the architecture correctly distinguishes:

`ACTION ≠ CONSTRAINT ≠ PREFERENCE`

and correctly stops when an explicit customer constraint cannot be satisfied.

## 5. Architectural Requirement Confirmed

A formal **Constraint & Conflict Resolution Layer** is required before implementation of customer-driven change handling.

Minimum rules:

1. Parse requested actions separately from constraints and preferences.
2. Check feasibility before mutating Design State.
3. Never silently trade one explicit requirement for another.
4. Detect unsatisfiable combinations explicitly.
5. Produce explainable alternatives.
6. Require customer decision when an explicit requirement must be relaxed.
7. Higher-order safety, legal and validated scientific constraints remain authoritative over customer preferences.
8. All accepted changes remain versioned, idempotent and reversible.

## 6. Governance Impact

This test does NOT by itself approve the new layer for production implementation.

Next gate:

- formalize Constraint & Conflict Resolution contract;
- reconcile with Design State, Change Request and Impact/Dependency contracts;
- review against Identity/Zone/Core authority boundaries;
- obtain Human Project Owner approval;
- only then update CURRENT-STATE and proceed to implementation.
