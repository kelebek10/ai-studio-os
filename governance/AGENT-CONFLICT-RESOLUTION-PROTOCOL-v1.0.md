# PAI-FORGE — Agent Conflict Resolution Protocol v1.0

Document ID: CONFLICT-001
Version: 1.0
Status: CONTROLLED DESIGN BASELINE
Branch: phase-1-3-foundation
Owner: Human Project Owner
Parent: AI-OPS-001
Constitutional Control: PAI-FORGE-001A
Task Contract: TASK-001
Result Gate: AI-RHG-001

## 1. Purpose

Prevent specialist-agent discussions from becoming unbounded loops, circular debate, repeated work, or autonomous escalation.

Agent collaboration is strictly bounded. A problem that is not resolved within the permitted conflict rounds must terminate and be returned to the project control layer for a new decision.

## 2. Mandatory Round Limit

The maximum number of conflict-resolution rounds for one logical problem is **3**.

Round count belongs to the logical conflict/request lineage, not merely to an individual task ID.

A new `task_id`, agent, model, message, branch or conversation does not reset the round counter when the work belongs to the same logical problem.

Required lineage fields:

- `conflict_id`
- `root_task_id`
- `correlation_id`
- `logical_problem_id`
- `round_number`
- `parent_round_id`
- `participants`
- `decision_state`

## 3. Round Semantics

- `ROUND-1`: first structured attempt to resolve the conflict.
- `ROUND-2`: second attempt using new evidence, correction or materially different analysis.
- `ROUND-3`: final allowed attempt.
- After `ROUND-3`, no further specialist-agent debate is permitted without a new control decision.

Repeating substantially identical arguments without new evidence does not create permission for another round.

## 4. Required Round Outcome

Every round must end in one of:

- `RESOLVED`
- `UNRESOLVED`
- `BLOCKED`
- `EVIDENCE_REQUIRED`
- `AUTHORITY_REQUIRED`
- `STOPPED`

Only `RESOLVED` may close the conflict as solved.

`UNRESOLVED` after Round 3 is terminal for the current collaboration cycle.

## 5. Round-3 Hard Stop

When Round 3 ends without a verified resolution:

1. all participating specialist-agent conversations are closed;
2. no fourth round may be automatically started;
3. no agent may reopen the same conflict autonomously;
4. the issue is returned to the project control layer;
5. a structured handoff is created containing the unresolved conflict, evidence, competing positions, attempted rounds, risks and required human/GPT decision;
6. status becomes `BLOCKED`, `REVIEW_REQUIRED`, or `HUMAN_ACTION_REQUIRED` according to the verified authority state.

This is a hard control, not a recommendation.

## 6. No Loop Evasion

The following are explicitly prohibited as methods of bypassing the three-round limit:

- creating a new task ID for the same logical problem;
- changing the conversation title or channel;
- replacing an agent while retaining the same unresolved problem;
- delegating to another agent without preserving lineage;
- restarting the workflow;
- creating a new branch solely to reset the counter;
- changing `correlation_id` without establishing a genuinely new logical problem;
- asking a manager agent to restart the same debate;
- using a different AI provider to continue the same unresolved debate;
- converting unresolved disagreement into PASS by consensus.

Logical-problem identity must therefore be preserved across delegation and escalation.

## 7. New Problem vs. Same Problem

A new conflict cycle is permitted only when the control layer records a materially new objective or evidence state and establishes a new `logical_problem_id`.

A new cycle must not be used merely to evade the Round-3 hard stop.

The control layer must retain a link to the previous conflict and explain why the new problem is materially distinct.

## 8. Evidence Requirement

Each round must record:

- exact participants;
- round number;
- task/correlation identity;
- evidence consulted;
- new evidence introduced;
- position or finding from each participant;
- unresolved disagreement, if any;
- outcome;
- timestamp;
- source commit/artifact identity where applicable.

AI prose alone cannot establish that a conflict was resolved.

## 9. Deterministic Enforcement

The round limit must eventually be enforced by deterministic Control logic, not by an LLM instruction alone.

Control must reject any attempt to create `round_number > 3` for the same logical problem.

Control must also reject a new task or correlation that attempts to continue an existing unresolved conflict without a verified new `logical_problem_id`.

Required future tests include:

- `CONF-01`: same logical request with a new task ID inherits the existing round count.
- `CONF-02`: Round 4 creation is rejected.
- `CONF-03`: agent replacement cannot reset the round count.
- `CONF-04`: branch/conversation restart cannot reset the round count.
- `CONF-05`: identical arguments without new evidence cannot advance the conflict.
- `CONF-06`: Round-3 unresolved state produces a terminal handoff.
- `CONF-07`: a genuinely new logical problem can begin a new cycle only through the control layer.

## 10. Manager-Agent Boundary

The Operations Manager may coordinate the discussion, collect evidence and prepare escalation.

It may not:

- silently extend the round limit;
- reset lineage;
- declare unresolved conflict resolved by consensus;
- suppress a Round-3 stop;
- reactivate a closed conflict without a new control decision.

## 11. Human / GPT Escalation

After a Round-3 unresolved outcome, the project control layer must determine the next route:

- GPT technical verification;
- additional evidence acquisition;
- specialist replacement for a new controlled cycle;
- Human Project Owner decision;
- permanent rejection/closure.

The escalation route must be explicit in the handoff.

## 12. Terminality and Auditability

A closed conflict remains historically queryable.

Terminal status cannot be changed merely by editing an informational status file.

Any re-opening requires a new controlled event linked to the prior conflict record.

## 13. Acceptance Criteria

CONF-01: Logical conflict lineage survives task/agent changes.

CONF-02: Maximum automatic conflict rounds are exactly three.

CONF-03: Round 4 is deterministically rejected.

CONF-04: No conversation/task/branch restart can reset the counter.

CONF-05: Round-3 unresolved conflict closes specialist-agent discussion.

CONF-06: A complete escalation handoff is produced after the hard stop.

CONF-07: Manager agents cannot extend or bypass the limit.

CONF-08: A new conflict cycle requires a verified materially new logical problem.

CONF-09: Historical conflict evidence remains traceable.

## 14. Current State

This is a controlled design baseline. Runtime conflict tracking, lineage persistence, deterministic enforcement and automated conversation closure require separate implementation and real evidence.

Until those controls are implemented and verified, the three-round rule is a mandatory design requirement but must not be represented as runtime-enforced PASS.
