# PAI-FORGE — Communication & Trigger Core v0.1

**Status:** ACTIVE / FIRST IMPLEMENTATION TARGET  
**Branch:** phase-1-3-foundation

## Objective

Establish the smallest reliable communication and triggering backbone required to place Gemini, Claude and Copilot into PAI-FORGE sequentially.

This layer exists to serve PAI-FORGE product development. It is not a generic AI Operating System.

## Minimal flow

CONTROL
→ TASK ENVELOPE
→ DISPATCH
→ TARGET AGENT
→ ACK
→ EXECUTION
→ RESULT + EVIDENCE
→ CONTROL

## Required contract

A task must have:

- task_id
- correlation_id
- agent
- task_type
- scope
- source_commit
- required_evidence
- prohibited_actions
- status
- result
- evidence

Minimum lifecycle:

VALIDATED → ROUTING → EXECUTING → COMPLETED

Failure:

EXECUTING → BLOCKED

No agent may self-approve trusted Core data.

## Trigger requirements

The first implementation must prove, with real evidence:

1. A valid task can be created.
2. The trigger reaches the intended agent/runtime.
3. ACK is received.
4. Execution occurs exactly once for the same idempotency key.
5. RESULT is returned.
6. Evidence is attached to the result.
7. Invalid/missing task data fails closed.
8. Unauthorized target/action is rejected.
9. Restart/replay does not create duplicate execution.
10. The full round can be traced by task_id + correlation_id.

## Explicitly deferred

Do not add these in v0.1:

- broad A2A orchestration
- multi-agent conflict rounds
- advanced round lineage
- generic Agent Registry expansion
- Claude auto-wakeup expansion
- GitHub Bridge expansion
- CI-001 expansion
- M15-A expansion
- generic shared AI Operating Layer

## AI placement order after PASS

1. Gemini — Landscape Research
2. Claude — Core Architecture / Implementation
3. Copilot — GitHub Engineering / Delivery

Each AI is introduced only after the previous integration passes its real trigger/ACK/RESULT/evidence test.

## Definition of done

Communication & Trigger Core is PASS only when a real end-to-end test demonstrates:

**task → trigger → agent → ACK → execution → result → evidence**

with replay/idempotency and fail-closed behavior proven.

Until then, no AI agent is considered integrated.
