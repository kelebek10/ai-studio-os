# PAI-FORGE — Communication & Trigger Core v0.1

**Status:** ACTIVE / FIRST IMPLEMENTATION TARGET  
**Branch:** phase-1-3-foundation

## Objective

Establish the smallest reliable communication and triggering backbone required to place Gemini, Claude and Copilot into PAI-FORGE sequentially.

This layer exists to serve PAI-FORGE product development. It is not a generic AI Operating System.

## Communication policy

**Agent-to-agent and AI-to-AI free-form conversation is prohibited.**

Agents communicate only through explicit task contracts, ACK/RESULT messages, evidence records, and controlled routing.

The **3-round rule applies only to an active problem-solving/conflict cycle**. It does not authorize general conversation, social exchange, exploratory chat, or unrestricted agent-to-agent messaging.

For a problem-solving cycle:

- maximum 3 controlled rounds
- each round must have a defined task/problem scope
- each response must produce actionable evidence or a clear resolution state
- unresolved after round 3 → BLOCKED / Human Gate
- no automatic fourth round

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
11. Unsolicited free-form agent-to-agent messaging is rejected or unavailable.
12. The 3-round limit is enforced only inside an explicitly declared problem-solving cycle.

## Explicitly deferred

Do not add these in v0.1:

- broad A2A orchestration
- unrestricted agent-to-agent chat
- multi-agent conflict infrastructure beyond the minimal 3-round problem-solving rule
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

with replay/idempotency, fail-closed behavior, communication containment, and problem-cycle round enforcement proven.

Until then, no AI agent is considered integrated.
