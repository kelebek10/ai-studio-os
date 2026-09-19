# PAI-FORGE — Agent Permission Model v1.0

Document ID: PERMISSION-001
Version: 1.0
Status: CONTROLLED DESIGN BASELINE
Branch: phase-1-3-foundation
Owner: Human Project Owner
Parent: AI-OPS-001
Constitutional Control: PAI-FORGE-001A
Agent Registry: AGENT-001
Task Contract: TASK-001
Result Gate: AI-RHG-001
Conflict Protocol: CONFLICT-001

## 1. Purpose

Define the permission boundary for registered AI agents participating in controlled PAI-FORGE work.

Registration identifies an agent; this model defines what the agent may and may not do. Permission does not create Human Project Owner authority, production authority or unrestricted Core mutation capability.

## 2. Permission Principles

- Least privilege.
- Explicit scope.
- Default deny.
- Task-bound access.
- Time/lineage-bound access where applicable.
- Separation of implementation, review and authority.
- No self-escalation.
- No authority through AI consensus.
- No production access by implication.
- Security and governance controls fail closed when required state is missing or unverifiable.

## 3. Permission Dimensions

Every operational permission shall be evaluated against:

- agent identity;
- lifecycle state;
- project and repository scope;
- task ID and correlation ID;
- logical problem / conflict lineage where applicable;
- allowed task class;
- tool access profile;
- environment;
- protected resource;
- requested action;
- current governance/policy version;
- evidence and provenance requirements.

A permission is valid only when all required dimensions are satisfied.

## 4. Agent Authority Classes

### Claude — AGENT-CLAUDE-001

Permitted within verified task scope:
- repository inspection;
- implementation;
- non-production tests;
- evidence generation;
- technical review when independently assigned;
- handoff preparation.

Forbidden:
- main modification/merge;
- human authorization;
- self-approval;
- production mutation;
- permission self-escalation;
- governance weakening;
- bypassing deterministic controls;
- extending a conflict beyond the permitted round limit.

### GPT — AGENT-GPT-001

Permitted:
- orchestration;
- architecture and QA coordination;
- independent verification of material handoffs;
- preparation of controlled next actions.

Forbidden:
- creating Human Project Owner authority;
- bypassing deterministic controls;
- silently overriding verified governance;
- extending conflict rounds beyond the hard limit.

### Specialist Agents

Gemini, Copilot and Kimi remain specialist/consortium roles until separately activated with verified permission and tool profiles.

## 5. Three-Round Conflict Hard Stop

The maximum automatic specialist-agent conflict-resolution allowance for one logical problem is **3 rounds**.

This is a permission boundary, not merely a conversation preference.

### Round permissions

- Round 1: permitted if the task and conflict lineage are valid.
- Round 2: permitted only when lineage proves Round 1 and the control layer authorizes continuation.
- Round 3: permitted only when lineage proves Round 2 and the control layer authorizes the final attempt.
- Round 4: **DENIED**.

No agent, manager, workflow, provider or connector may grant itself Round 4.

## 6. Round-4 Rejection

Any request attempting `round_number > 3` for the same `logical_problem_id` must be rejected by deterministic Control.

Required denial result:

`BLOCKED / CONFLICT_ROUND_LIMIT_EXCEEDED`

The denial must preserve:
- conflict ID;
- logical problem ID;
- requested round;
- last valid round;
- requesting agent;
- task/correlation identity;
- policy version;
- evidence/provenance reference.

The rejected attempt must not create an executable new round.

## 7. Counter Reset Prohibition

Agents and orchestration components must not reset or evade the conflict counter by:

- creating a new task ID;
- changing correlation ID without a verified new logical problem;
- changing agent/provider;
- opening a new conversation/channel;
- changing conversation title;
- restarting the workflow;
- creating a new branch solely to reset lineage;
- delegating the same unresolved problem without lineage;
- creating a replacement task that omits prior conflict history.

The counter belongs to the **logical problem lineage**, not to the task, agent, conversation, branch or provider.

A new conflict cycle is permitted only when deterministic Control verifies a materially new objective or evidence state and creates a new `logical_problem_id` linked to the previous conflict.

## 8. Round Advancement Conditions

A new round requires:

1. valid conflict lineage;
2. previous round recorded;
3. previous outcome is eligible for continuation;
4. materially new evidence, correction or analysis where required;
5. valid agent/task permission;
6. no terminal state;
7. round number exactly equal to previous round + 1;
8. `round_number <= 3`.

Repeated arguments without meaningful new evidence do not justify another round.

## 9. Terminal Notification and Handoff

When Round 3 ends without a verified resolution, the permission layer must deny further specialist-agent discussion and trigger the controlled terminal handoff path.

The terminal notification must contain at minimum:

- `conflict_id`;
- `logical_problem_id`;
- `root_task_id`;
- `correlation_id`;
- final round number;
- participants;
- each participant's final finding;
- evidence references;
- unresolved disagreement;
- risks/impact;
- source commit/artifact identity where applicable;
- terminal reason;
- required next authority/action.

The resulting project-control state shall be one of the verified escalation states:

`BLOCKED`, `REVIEW_REQUIRED`, or `HUMAN_ACTION_REQUIRED`.

Notification is informational unless the deterministic control path records the corresponding state transition. Telegram or another messaging channel may mirror the notification but cannot authorize reopening or continuation.

## 10. Conversation Closure

After an unresolved Round 3:

- participating specialist conversations must be closed;
- no automatic follow-up message may reopen the discussion;
- no manager agent may restart the same debate;
- no new specialist task may continue the same logical problem without a verified new control cycle;
- historical evidence must remain queryable.

A closed conflict is terminal for that collaboration cycle.

## 11. Reopening / New Cycle

Reopening is not a permission to continue the old conversation.

A new cycle requires a new deterministic control event with:

- a new `logical_problem_id` only if the problem is materially distinct;
- explicit link to the prior conflict;
- explanation of the material change;
- fresh task identity;
- fresh evidence/provenance evaluation;
- applicable permission evaluation.

A new cycle cannot be created solely because an agent wants another attempt.

## 12. Manager-Agent Restrictions

An Operations Manager may coordinate, collect evidence and submit escalation, but may not:

- increase the 3-round limit;
- reset the counter;
- alter conflict lineage to avoid the limit;
- convert unresolved disagreement into PASS;
- suppress terminal notification;
- reopen a closed conflict without deterministic control authorization.

## 13. Fail-Closed Conditions

Permission must be denied when any required value is missing, malformed, stale, conflicting or unverifiable, including:

- unknown agent;
- inactive/suspended/revoked agent;
- invalid task scope;
- missing conflict lineage;
- ambiguous logical problem identity;
- invalid policy version;
- missing evidence where required;
- provenance mismatch;
- attempted counter reset;
- round greater than 3;
- terminal conflict state;
- authority mismatch.

## 14. Acceptance Criteria

PERM-01: Permissions are separate from agent registration.

PERM-02: Default-deny and least-privilege rules are explicit.

PERM-03: Claude cannot self-escalate or create human authority.

PERM-04: Maximum automatic conflict rounds are exactly three.

PERM-05: Round 4 is deterministically denied.

PERM-06: Counter reset through task/agent/conversation/branch/provider changes is denied.

PERM-07: Round-3 unresolved conflict terminates specialist discussion.

PERM-08: Terminal handoff contains sufficient lineage, evidence and escalation data.

PERM-09: Manager agents cannot extend or bypass the limit.

PERM-10: New conflict cycles require verified material distinction and deterministic control.

PERM-11: Missing or unverifiable permission/lineage state fails closed.

## 15. Current State

This is a controlled design baseline. Runtime permission enforcement, conflict-lineage persistence, deterministic Round-4 rejection and automated terminal conversation closure require separate implementation and real evidence.

Until those controls are implemented and verified, this document must not be represented as runtime-enforced PASS.
