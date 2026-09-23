# PAI-FORGE — AI Communication Loop v1.0

Document ID: COMM-001
Version: 1.0
Status: CONTROLLED DESIGN BASELINE
Branch: phase-1-3-foundation
Owner: Human Project Owner
Parent: AI-OPS-001
Constitutional Control: PAI-FORGE-001A
Task Contract: TASK-001
Result Gate: AI-RHG-001
Conflict Protocol: CONFLICT-001
Permission Model: PERMISSION-001

## 1. Purpose

Define the durable communication path between Human Project Owner, GPT-5.6 Luna, Claude and specialist agents without allowing communication loops to become autonomous, unbounded or authority-bearing.

## 2. Canonical Communication Path

`HUMAN REQUEST → GPT CONTROL → TASK RECORD → AGENT ACKNOWLEDGEMENT → WORK → RESULT HANDOFF → GPT VERIFICATION → NEXT CONTROLLED ACTION`

GitHub is the durable project communication and evidence surface. Ephemeral chat and Telegram messages cannot replace the canonical task/result record.

## 3. Communication Classes

The system must distinguish communication purpose before counting rounds:

- `EXECUTION`: acknowledgement, progress, evidence delivery and result handoff. These are task lifecycle events and are not conflict rounds.
- `CLARIFICATION`: bounded clarification needed to execute an already controlled task. It must remain linked to the same task and cannot expand scope or authority.
- `CONFLICT_RESOLUTION`: substantive disagreement or unresolved technical decision on one logical problem. This is subject to the three-round hard stop.
- `REVIEW_REWORK`: response to a verified review finding. It remains bounded by the same logical lineage unless the control layer verifies a materially new problem.

Changing communication class cannot reset an existing conflict lineage.

## 4. GPT ↔ Claude Conversation Boundary

GPT and Claude may exchange multiple lifecycle events required to complete a controlled task, but a substantive problem-resolution conversation for the same `logical_problem_id` is limited to three rounds.

One round is a structured exchange that advances the same unresolved problem, for example:

`REQUEST/FINDING → CLAUDE ANALYSIS → GPT/CONTROL RESPONSE`

The exact transport may vary, but the round must be represented in the canonical lineage record.

Routine ACK, progress, evidence upload and final handoff do not create additional conflict rounds merely because they are messages.

## 5. Three-Round Hard Stop

For `CONFLICT_RESOLUTION` or an equivalent unresolved review/rework loop:

- Round 1 = first controlled resolution attempt.
- Round 2 = second attempt using new evidence, correction or materially different analysis.
- Round 3 = final allowed attempt.
- Round 4 = deterministically denied.

After an unresolved Round 3, GPT and Claude must not continue the same substantive debate. The communication cycle becomes terminal and returns to project control.

Required terminal states are `BLOCKED`, `REVIEW_REQUIRED` or `HUMAN_ACTION_REQUIRED`, according to verified authority state.

## 6. Lineage

Every bounded substantive exchange must preserve:

- `conflict_id`
- `root_task_id`
- `correlation_id`
- `logical_problem_id`
- `round_number`
- `parent_round_id`
- producer/consumer agent IDs
- source commit
- policy/permission version
- evidence references
- decision/control state

The round counter belongs to the logical problem, not to a chat window, task ID, agent, provider, branch, workflow or channel.

## 7. No Loop Evasion

The following cannot reset or bypass the three-round limit:

- new task ID for the same problem;
- new chat, channel or conversation title;
- agent/provider replacement;
- workflow restart;
- new branch created solely to restart discussion;
- correlation ID change without a verified new logical problem;
- manager restart or delegation without lineage;
- converting disagreement to PASS by consensus.

## 8. New Cycle

A new substantive cycle is allowed only when deterministic Control verifies a materially new objective or evidence state and assigns a new `logical_problem_id` linked to the previous conflict.

A new cycle is not a disguised Round 4.

## 9. Terminal Handoff

When the hard stop occurs, the system must record:

- final round and outcome;
- participants;
- competing findings;
- evidence and provenance;
- unresolved issue;
- risks/impact;
- source commit/artifact identity;
- terminal reason;
- required next authority/action.

The terminal handoff is an evidence event, not an approval event.

## 10. Authority Boundary

- GPT coordinates, verifies and prepares the next controlled action within its authority.
- Claude executes assigned work, reports evidence and may provide independent technical analysis.
- Specialist agents operate only within registered permissions.
- No agent can create Human Project Owner authority.
- AI consensus is not authority.
- Telegram is notification-only.

## 11. Fail-Closed Rules

Communication must stop or enter `WAITING`, `UNVERIFIED` or `BLOCKED` when identity, task, scope, lineage, policy version, evidence, provenance or authority cannot be verified.

Missing or contradictory communication state must never be silently interpreted as permission to continue.

## 12. Runtime Requirement

This document is a design baseline. Runtime dispatch, acknowledgement capture, communication event persistence, deterministic round enforcement and automated terminal closure require separate implementation and real evidence.

Until those controls are verified, GPT-Claude communication must not be represented as fully automated or runtime-enforced.

## 13. Acceptance Criteria

COMM-01: Every controlled task has one canonical task identity.

COMM-02: Claude acknowledgement is captured before controlled work proceeds.

COMM-03: Result handoff is bound to task, branch, commit and evidence.

COMM-04: GPT verification occurs before the next protected stage.

COMM-05: Substantive GPT-Claude problem-resolution loops are bounded to three rounds.

COMM-06: Round 4 is deterministically rejected before execution.

COMM-07: Task/chat/provider/branch/workflow changes cannot reset conflict lineage.

COMM-08: Unresolved Round 3 produces terminal handoff and stops substantive debate.

COMM-09: New cycles require verified materially new logical problems.

COMM-10: Missing or contradictory communication state fails closed.


## 14. ZERO-FREE-CHAT RULE — MANDATORY

PAI-FORGE is a task network, not a free-conversation network.

AI models, workers and specialist agents MUST NOT engage in free, social, exploratory or unrelated AI-to-AI conversation.

Permitted communication is limited to:
- task assignment;
- task acknowledgement;
- task-scoped execution/progress;
- evidence/result handoff;
- bounded clarification directly required by the assigned task;
- conflict resolution for a concrete problem;
- review/rework directly linked to the same task and problem lineage;
- security/governance status reporting.

If a message is not necessary to execute, verify, secure, document or hand off the active task, it is not permitted.

The runtime MUST reject messages that lack a valid task context or that attempt to initiate an unbounded conversation.

## 15. WORK-FOCUS ENFORCEMENT

Every active AI/agent must remain focused on its assigned scope.

An agent shall not:
- initiate unrelated discussion;
- request opinions without a task need;
- continue discussion after a result has been handed off;
- create an open-ended discussion thread;
- use another task/channel/provider to continue a blocked discussion;
- reset conflict rounds through conversational re-entry.

Normal work follows:

`ASSIGN → EXECUTE → VERIFY → HANDOFF`

Only an actual unresolved problem opens:

`CONFLICT → ROUND 1 → ROUND 2 → ROUND 3 → BLOCKED/HUMAN GATE`

Security violations bypass the conflict loop and are blocked immediately.

## 16. GLOBAL THREE-ROUND RULE

The three-round hard stop applies across the entire PAI-FORGE AI/agent hierarchy, not only to GPT↔Claude communication.

It covers:
- AI model ↔ AI model;
- worker ↔ worker;
- specialist agent ↔ specialist agent;
- reviewer ↔ implementer;
- researcher ↔ evidence/reviewer;
- team ↔ team;
- orchestration-level substantive disputes.

The round counter is attached to the `logical_problem_id` and cannot be reset by changing task ID, agent, model, workflow, channel, branch or conversation.

## 17. SECURITY / GOVERNANCE OBSERVATION PATH

The Security/Governance control boundary observes and enforces the communication policy across all layers, including the orchestrator.

The security layer is not a subordinate conversational worker and does not participate in free discussion.

Its communication with upper layers is limited to:
- security status;
- policy violations;
- blocks;
- risk findings;
- required control actions;
- verified clearance/status.

The Human Project Owner remains the final authority.

## 18. TELEGRAM HUMAN CONTROL CHANNEL

Telegram is the human-facing operational channel.

Canonical human path:

`HUMAN PROJECT OWNER ↔ TELEGRAM ↔ SECURITY/GATEWAY ↔ GPT-5.6 LUNA ORCHESTRATOR`

Telegram messages are not the durable source of truth. Task, decision, evidence, status and checkpoint records MUST be persisted in the controlled project repository/evidence system.

Telegram may carry:
- human commands;
- status reports;
- blocked/problem notifications;
- human-gate requests;
- verified completion summaries.

Telegram MUST NOT be used to bypass governance, approval, provenance or task contracts.

## 19. CONTROLLED RESUME REQUIREMENT

A new chat/session MUST NOT be treated as a new project state.

Before continuing work, the active AI coordinator must read the current controlled checkpoint and relevant governance documents from the repository, verify the current branch/commit/state, and resume from the recorded position.

The latest checkpoint is authoritative for operational continuity; historical chat memory is not a substitute for the checkpoint.

