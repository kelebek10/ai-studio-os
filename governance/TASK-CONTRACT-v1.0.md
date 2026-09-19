# PAI-FORGE — TASK CONTRACT v1.0

Document ID: TASK-001
Version: 1.0
Status: CONTROLLED DESIGN BASELINE
Branch: phase-1-3-foundation
Owner: Human Project Owner
Parent: AI-OPS-001
Constitutional Control: PAI-FORGE-001A
Result Gate: AI-RHG-001

## 1. Purpose

Define the minimum contract required for a controlled task to be assigned to an AI/agent, executed within scope, and returned through the governed result handoff path.

## 2. Required Task Identity

Every controlled task shall have:

- `task_id`
- `correlation_id`
- objective
- assigned producer/agent
- task status
- creation timestamp
- source branch
- source commit
- governance/policy references
- scope
- acceptance criteria
- required evidence
- prohibited actions
- handoff location
- human-action requirement

Task identity shall remain stable across the task lifecycle.

## 3. Assignment Rule

A task is not operationally assigned merely because it exists in a document or chat message.

The assigned agent must be able to retrieve the canonical task record and verify:

1. task identity;
2. current state;
3. assigned role;
4. permitted scope;
5. branch and source commit;
6. acceptance criteria;
7. required evidence;
8. prohibited actions;
9. canonical result handoff location.

If these cannot be verified, the agent shall remain `WAITING` or `BLOCKED` and shall not improvise.

## 4. Lifecycle

Controlled task lifecycle:

`CREATED → ASSIGNED → ACKNOWLEDGED → WORKING → RESULT_SUBMITTED → GPT_REVIEW → VERIFIED | REWORK_REQUIRED | BLOCKED | HUMAN_ACTION_REQUIRED → CLOSED`

No producer may skip the result verification gate.

## 5. Scope Boundary

The task contract shall explicitly define what the agent may change, inspect, create, execute or review.

Anything outside declared scope is prohibited unless a new controlled task or approved scope amendment is issued.

## 6. Evidence Requirement

Acceptance criteria shall state what constitutes real execution evidence.

Documentation, model reasoning, AI consensus or a claimed PASS is insufficient where runtime proof is required.

Missing evidence results in `UNVERIFIED` / `BLOCKED` as applicable.

## 7. Security and Authority

The task contract cannot grant authority beyond the applicable Agent Registry, Permission Model, Tool Access Policy, constitutional rules or Human Project Owner authorization.

A task cannot authorize:

- direct protected Core bypass;
- self-granted permissions;
- human authorization creation;
- production mutation without separate authorization;
- policy weakening;
- silent scope expansion.

## 8. Communication and Handoff

The canonical communication path is:

**TASK RECORD → AGENT ACKNOWLEDGEMENT → PROGRESS/RESULT → CANONICAL HANDOFF → GPT VERIFICATION → NEXT CONTROLLED ACTION**

GitHub is the durable task and handoff surface.

Ephemeral chat may notify or explain, but does not replace the canonical task record.

## 9. Failure Rules

The task shall stop or remain waiting when there is:

- missing task identity;
- missing assignment;
- stale source state;
- scope ambiguity;
- permission mismatch;
- missing required evidence;
- contradictory governance;
- security uncertainty;
- failed acceptance criterion;
- result/handoff mismatch.

No failure condition may be silently converted into success.

## 10. Acceptance Criteria

TASK-01: An assigned agent can deterministically identify its task and scope.

TASK-02: Task identity is traceable from assignment through result handoff.

TASK-03: Required evidence and acceptance criteria are explicit.

TASK-04: Scope and authority boundaries are explicit.

TASK-05: Producer result cannot bypass GPT verification.

TASK-06: Missing or contradictory task context prevents execution.

TASK-07: The contract is reusable by future registered agents without granting unrestricted authority.

## 11. Current State

This is a controlled design baseline. Runtime task dispatch, acknowledgement, event persistence and automatic progression remain pending independent implementation and evidence.