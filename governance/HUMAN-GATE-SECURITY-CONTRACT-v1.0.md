# PAI-FORGE — M16.8 HUMAN GATE + SECURITY CONTRACT v1.0

**Status:** IMPLEMENTED / TESTED IN CONTROLLED RUNTIME
**Scope:** M16.8 non-production runtime boundary
**Source commit:** 7222fa7e620672329ac99f41e07b8efc7db1c892

## Purpose

M16.8 establishes the runtime boundary between evidence and human action. AI output, reviewer status, actor metadata, or textual `APPROVED` can never constitute human approval.

## Enforced flow

`REVIEW → EVIDENCE → SECURITY INSPECTION → HUMAN_GATE → HUMAN ACTION OUTSIDE AI RUNTIME`

## Controls

1. Security inspection accepts only `EVIDENCE` state.
2. A task must explicitly declare `requires_human=True`.
3. Evidence must exist before the human gate is requested.
4. Actor-supplied `approval` / `approved_by` fields are rejected.
5. Evidence with producer status `APPROVED` is rejected.
6. Human Gate creates a request only; it has no approve operation.
7. `APPROVED` is not a `TaskState` and cannot be created by runtime transition.
8. Production mutation and M14 authority remain outside this runtime stage.

## Security property

The runtime can place work in `HUMAN_GATE`; it cannot manufacture the human authority required to clear that gate.

## Verification

`tests/runtime/test_human_gate_security.py` exercises:
- valid evidence → human gate;
- actor approval spoof → BLOCKED;
- evidence approval assertion → BLOCKED;
- undeclared human gate → BLOCKED.

M14 remains the authoritative approval mechanism for protected governance mutation.
