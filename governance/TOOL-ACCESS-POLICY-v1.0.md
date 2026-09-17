# PAI-FORGE — Tool Access Policy v1.0

Document ID: TOOL-001
Version: 1.0
Status: CONTROLLED DESIGN BASELINE
Branch: phase-1-3-foundation
Owner: Human Project Owner
Parent: AI-OPS-001
Constitutional Control: PAI-FORGE-001A
Agent Registry: AGENT-001
Permission Model: PERMISSION-001
Task Contract: TASK-001
Result Gate: AI-RHG-001
Conflict Protocol: CONFLICT-001

## 1. Purpose

Define the controlled tool boundary for registered AI agents. Tool access is an enforcement layer below agent identity and permission evaluation; possessing a tool connection never grants authority by itself.

## 2. Core Rules

- Default deny.
- Tool access is task-bound, agent-bound, repository/branch-bound and environment-bound.
- Permission Model evaluation must succeed before a protected tool action is executable.
- Tool availability is not permission.
- Tool output is evidence/input, not authority.
- No tool may bypass deterministic Control.
- No tool may create Human Project Owner authority.
- No tool may silently expand its own scope.
- Production and protected Core mutation remain separately controlled and denied unless explicitly authorized by a verified policy path.

## 3. Tool Classes

### Read tools

May inspect approved repository state, task records, governance documents and evidence within assigned scope.

### Write tools

May create or modify files only inside an explicitly permitted branch/task scope. Governance/security-sensitive writes require the applicable review and handoff controls.

### Execution tools

May run approved non-production tests and verification workloads only when the task contract and environment policy permit execution.

### Communication tools

May publish task progress, result handoffs and terminal notifications. Communication channels cannot authorize, verify or reopen protected work.

## 4. Conflict-Round Tool Boundary

Conflict-resolution tools are additionally constrained by Permission Model PERMISSION-001.

For one `logical_problem_id`:

- Round 1: tool calls permitted when lineage and task permissions are valid.
- Round 2: tool calls permitted only after deterministic continuation authorization.
- Round 3: tool calls permitted only as the final controlled attempt.
- Round 4 or greater: **DENIED**.

The tool layer must not accept a round request merely because a new task ID, agent, provider, branch, conversation or workflow execution is supplied.

The conflict counter is inherited from the verified logical-problem lineage.

## 5. Counter-Reset Protection

Tool requests must be rejected when they attempt to reset conflict lineage through:

- new task ID;
- new correlation ID without verified material distinction;
- agent/provider substitution;
- new conversation/channel;
- workflow restart;
- branch restart;
- delegation without parent lineage;
- omission or alteration of prior round history.

Required deterministic denial reason:

`BLOCKED / CONFLICT_LINEAGE_RESET_ATTEMPT`

## 6. Terminal Round Enforcement

After an unresolved Round 3, conflict-resolution tools must deny further specialist discussion for that logical problem.

Required denial reason for continuation:

`BLOCKED / CONFLICT_TERMINAL_STATE`

The tool layer must permit terminal handoff/notification actions required by the control path, but those actions cannot reopen the conflict.

Telegram or equivalent notification adapters may mirror the terminal event only. They cannot alter the conflict state, round number, lineage or authority.

## 7. Protected Actions

The following actions require deterministic Control and applicable higher-level authority checks before execution:

- protected Core mutation;
- production deployment or promotion;
- human-approval state transition;
- permission expansion;
- agent activation/escalation;
- conflict-round continuation;
- conflict reopening;
- governance-policy weakening.

## 8. Fail-Closed Conditions

Tool execution must be denied when required identity, task, scope, policy, lineage, evidence, environment or authority state is missing, stale, malformed, conflicting or unverifiable.

A tool error or unavailable verification path must not be interpreted as permission.

## 9. Audit Requirements

Every protected tool action must be attributable to:

- agent ID;
- task ID;
- correlation ID;
- logical problem ID where applicable;
- action/tool identity;
- source commit;
- policy/permission version;
- requested round where applicable;
- decision/result;
- evidence/provenance reference.

## 10. Acceptance Criteria

TOOL-01: Tool access is separate from agent registration.

TOOL-02: Default-deny is enforced by design.

TOOL-03: Tool availability cannot create authority.

TOOL-04: Conflict-round requests are bounded to three rounds.

TOOL-05: Round 4 is denied before execution.

TOOL-06: Counter-reset attempts are denied through deterministic lineage checks.

TOOL-07: Terminal Round-3 state blocks further specialist discussion.

TOOL-08: Terminal notification/handoff cannot reopen the conflict.

TOOL-09: Protected actions require deterministic Control and applicable authority.

TOOL-10: Missing or unverifiable control state fails closed.

## 11. Current State

This is a controlled design baseline. Runtime tool-policy enforcement and real adversarial evidence remain required. Until independently implemented and verified, this document must not be represented as runtime-enforced PASS.
