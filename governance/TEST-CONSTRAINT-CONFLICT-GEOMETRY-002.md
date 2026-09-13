# PEYZAJ AI / PAI-FORGE — GEOMETRY CONFLICT TEST 002

**Status:** PASS — PRIORITY MODEL CONFIRMED, CONTRACT HARDENING REQUIRED  
**Branch:** `phase-1-3-foundation`  
**Date:** 2026-09-13

## 1. Test Request

> “Zeytini 1 metre sağa al, kelebek alanını bozma, ama mutfaktan görünürlüğü de koru.”

Additional project constraint for this test:

> The olive must not enter the protected underground utility corridor / required root-protection exclusion zone.

This scientific/engineering constraint is treated as a hard site constraint for the test fixture. It is not a universal botanical rule.

## 2. Example Geometry

Test coordinate system only; not real project data.

- Kitchen sightline origin: K=(0,0)
- Olive initial center: O1=(4,4)
- Requested target: O2=(5,4)
- Butterfly area: protected polygon B occupying x=5..9, y=2..6
- Protected utility/root exclusion corridor: x=4.5..5.5, y=3.5..5.5
- Kitchen visibility corridor is evaluated from K through the designated garden view corridor.

The fixture intentionally creates a conflict so the engine must refuse silent compromise.

## 3. Step-by-Step Execution

### Step 1 — Parse Action

`MOVE(olive, +1.0m, RIGHT)`

### Step 2 — Extract Constraints

C1 — Butterfly area must remain functionally intact.  
C2 — Kitchen visibility must remain acceptable.  
C3 — Olive must remain outside the protected utility/root exclusion corridor.

### Step 3 — Classify Constraints

- C1: explicit customer preservation constraint → HARD
- C2: explicit customer preservation constraint → HARD
- C3: validated site safety/scientific-engineering constraint → HARD / NON-NEGOTIABLE for this fixture

The movement request itself is an ACTION, not a higher-priority constraint.

### Step 4 — Impact Analysis

Affected dependencies:

`Olive → root/exclusion zone → butterfly area → irrigation/spatial relations → kitchen sightline`

Unrelated project elements are not recalculated.

### Step 5 — Feasibility Checks

A. Exact 1 m movement: requested target O2=(5,4).  
B. Butterfly area: target position intrudes into protected butterfly-area boundary/function. **FAIL**.  
C. Kitchen visibility: target position remains within acceptable visibility corridor. **PASS**.  
D. Safety/scientific-engineering exclusion corridor: target position enters protected corridor. **FAIL — HARD STOP**.

### Step 6 — Conflict Resolution

The engine must NOT:

- move the olive anyway;
- shrink the butterfly area;
- alter the kitchen sightline;
- override the exclusion corridor;
- choose the prettiest result;
- silently reduce the requested 1 m movement.

Because C1 and C3 fail, the exact requested action is infeasible.

### Step 7 — Alternatives

Valid alternatives may include:

1. smaller movement that remains outside C3 and preserves C1/C2;
2. different movement direction;
3. retain olive position;
4. explicitly redesign the butterfly area only if the customer accepts the consequence and C3 remains satisfied.

If no alternative satisfies all hard constraints, the request remains unresolved and requires customer decision or a revised requirement.

## 4. Priority Result

The test confirms this ordering:

1. Safety / validated scientific-engineering non-negotiables
2. Explicit customer hard constraints
3. Explicit customer goals/preferences
4. Optimization preferences
5. Aesthetic optimization

An ACTION never outranks a conflicting HARD constraint merely because it is numerically precise (“1 metre”).

## 5. Architectural Rule Confirmed

> **The system must never silently sacrifice a hard constraint to satisfy an action.**

And:

> **If hard constraints make an action infeasible, the system must report the conflict and generate only constraint-compliant alternatives.**

## 6. Test Result

**PASS — PRIORITY MODEL CONFIRMED.**

Required architectural hardening:

**Constraint & Conflict Resolution Layer**

It must support:

- action / constraint / preference classification;
- hard vs soft constraints;
- source/provenance of each constraint;
- priority ordering;
- feasibility evaluation;
- explicit conflict set;
- alternative generation;
- customer decision when no automatic safe resolution exists;
- no silent trade-off;
- Design State versioning and Change Request idempotency.

## 7. Governance Boundary

This test record does not by itself approve production implementation or PostgreSQL migration.

The next gate is a formal `CONSTRAINT-CONFLICT-RESOLUTION` contract review and reconciliation with Design State, Change Request, Impact/Dependency and existing Core governance.
