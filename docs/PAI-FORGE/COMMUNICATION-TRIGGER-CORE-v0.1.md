# PAI-FORGE — Communication & Trigger Core v0.1

**Status:** ACTIVE / FIRST IMPLEMENTATION TARGET  
**Branch:** phase-1-3-foundation

## Objective

Establish the smallest reliable communication and triggering backbone required to place Gemini, Claude and Copilot into PAI-FORGE sequentially.

This layer exists to serve PAI-FORGE product development. It is not a generic AI Operating System.

## Communication policy — HARD RULE

**All AI-to-AI and agent-to-agent communication is task-scoped only.**

Free-form conversation is prohibited, including:
- AI ↔ AI free-form chat
- agent ↔ agent free-form chat
- specialist-agent ↔ specialist-agent free-form chat within the same AI
- unrestricted or infinite conversation, including GPT-5.6

An AI or agent may communicate only as part of an explicitly assigned task and only through the defined task contract, controlled routing, ACK/RESULT messages, and evidence records.

**No communication channel may exist outside the assigned task scope.**

### Problem-solving exception — strictly bounded

The **3-round rule exists only for an explicitly declared problem-solving/conflict-resolution cycle inside an assigned task.**

It does not authorize:
- general conversation
- social exchange
- exploratory chat
- open-ended discussion
- task-independent agent communication
- automatic continuation after the problem-solving cycle

For a declared problem-solving cycle:
- maximum **3 controlled rounds**
- each round must remain within the declared problem scope
- each round must produce actionable evidence or a clear resolution state
- unresolved after round 3 → **BLOCKED / Human Gate**
- **no automatic fourth round**
- after the cycle ends, communication returns to the normal task-contract flow

This rule applies equally to integrated AIs and their internal specialist agents.

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
11. Any unsolicited or out-of-task AI/agent message is rejected or unavailable.
12. The 3-round limit is enforced only inside an explicitly declared problem-solving cycle.
13. No AI or agent can initiate or continue communication outside an assigned task scope.
14. Internal specialist agents are subject to the same communication containment rules.
15. A fourth problem-solving round is rejected/blocked.

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

with replay/idempotency, fail-closed behavior, **task-scoped communication containment**, and **problem-cycle-only 3-round enforcement** proven.

Until then, no AI agent is considered integrated.
