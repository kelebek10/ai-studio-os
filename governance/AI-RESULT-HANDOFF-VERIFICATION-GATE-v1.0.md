# PAI-FORGE — AI RESULT HANDOFF & VERIFICATION GATE

Document ID: AI-RHG-001
Version: 1.0
Status: CONTROLLED DESIGN BASELINE
Branch: phase-1-3-foundation
Owner: Human Project Owner
Parent: AI-OPS-001
Constitutional Control: PAI-FORGE-001A

## 1. Purpose

Ensure that work assigned to an AI/agent is explicitly delivered back to the project control layer, independently verified, and only then allowed to trigger the next controlled stage.

The communication chain is:

**TASK ASSIGNED → AGENT AWARE → WORK → RESULT HANDOFF → GPT REVIEW → VERIFIED / REJECTED → NEXT CONTROLLED ACTION**

No agent result is authoritative merely because the agent produced it.

## 2. Communication Requirement

A controlled task shall have one canonical task identity and one canonical handoff location.

The assigned agent must be able to determine:

- what task it owns;
- why the task exists;
- current governance state;
- approved branch/scope;
- acceptance criteria;
- required evidence;
- prohibited actions;
- where to report progress and final result.

If the agent cannot reliably obtain this context, the task state is `WAITING` or `BLOCKED`; the agent shall not improvise scope.

## 3. Result Envelope

Every material result handoff shall identify, where applicable:

- `task_id`
- `correlation_id`
- `producer`
- `producer_status`
- `result_timestamp`
- `source_commit`
- `artifact_digest`
- `changed_or_reviewed_files`
- `tests_executed`
- `evidence_refs`
- `scope`
- `known_gaps`
- `unresolved_risks`
- `recommended_next_action`
- `human_action_required`

Missing critical identity, scope or evidence fields prevent verification.

## 4. Handoff States

Canonical handoff states are:

- `NOT_RECEIVED`
- `RECEIVED`
- `PENDING_GPT_REVIEW`
- `GPT_VERIFIED`
- `GPT_REJECTED`
- `HUMAN_ACTION_REQUIRED`
- `BLOCKED`
- `STALE`

`GPT_VERIFIED` is a verification state, not human authorization.

## 5. Authority Boundary

The producer's result is an evidence claim/input to the control layer.

The producer cannot:

- self-verify its own critical result;
- convert its own result into an authoritative completion state;
- trigger a protected next stage solely from its own PASS;
- bypass GPT review where this gate applies;
- manufacture missing evidence.

AI consensus does not replace verification.

## 6. GPT Verification Gate

Before a next controlled stage is initiated, GPT shall verify, as applicable:

1. task identity and correlation;
2. producer identity and assigned scope;
3. active branch and source commit;
4. artifact identity/digest when applicable;
5. evidence references and execution reality;
6. acceptance criteria;
7. contradictions or stale state;
8. security/governance impact;
9. unresolved risks and known gaps;
10. compatibility with current governance state.

If verification cannot be completed, progression remains `PENDING_GPT_REVIEW`, `UNVERIFIED`, `BLOCKED` or `STALE` as appropriate.

## 7. Next-Action Gate

A producer result shall never automatically authorize the next protected stage.

Only after GPT verification may the next task be prepared/queued, and any Human Project Owner approval requirement remains binding.

A verified result may therefore produce:

- `NEXT_STAGE_READY`
- `HUMAN_ACTION_REQUIRED`
- `BLOCKED`
- `REWORK_REQUIRED`

These are control outcomes, not producer claims.

## 8. Communication Channels

GitHub is the canonical durable project communication/evidence surface for controlled work.

Claude, GPT, Gemini, Copilot and other participating systems shall use the governed task/handoff records rather than relying on ephemeral chat state.

Telegram may mirror operational notifications such as:

- task started;
- result received;
- GPT review pending;
- blocked;
- human action required;
- verified next action ready.

Telegram cannot approve, verify, alter provenance, or change authority/state by itself.

## 9. Missing Communication / Stale Result

If a task is assigned but no canonical handoff/result is received, the state is `WAITING` rather than silently assumed complete.

If a result exists but cannot be bound to the correct task, commit, artifact, scope or evidence, it is `STALE`, `UNVERIFIED` or `BLOCKED` as applicable.

No silent progression is permitted.

## 10. Acceptance Criteria

RHG-01: Claude can identify an assigned task and its canonical handoff location.

RHG-02: A material result is traceable to task, producer, scope and source state.

RHG-03: Producer PASS cannot bypass GPT verification.

RHG-04: Missing or stale result cannot trigger the next stage.

RHG-05: GPT verification is distinguishable from Human Project Owner authorization.

RHG-06: Telegram remains notification-only.

RHG-07: The communication path is reusable for future registered agents and projects without granting unrestricted authority.

## 11. Current State

This is a controlled design baseline. Runtime implementation, automatic task dispatch, event storage and notification integration require separate verified controls and evidence.
