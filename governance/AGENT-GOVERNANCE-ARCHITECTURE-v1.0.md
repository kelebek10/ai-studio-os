# PAI-FORGE — AGENT GOVERNANCE ARCHITECTURE v1.1

Document ID: AGENT-GOV-001
Version: 1.1
Status: CONTROLLED DESIGN BASELINE
Branch: phase-1-3-foundation
Owner: Human Project Owner
Parent: AI-OPS-001
Constitutional Control: PAI-FORGE-001A
Registry: AGENT-001
Permission Model: PERMISSION-001
Task Contract: TASK-001
Result Gate: AI-RHG-001
Tool Policy: TOOL-001
Conflict Protocol: CONFLICT-001
Owner Intervention Policy: OWNER-INT-001

## 1. Purpose

Define the permanent authority, delegation, communication, oversight and loop-prevention architecture for PAI-FORGE agents.

This architecture separates operational management from independent oversight and uses risk-based intervention rather than continuous approval gates.

## 2. Authority Hierarchy

The authoritative hierarchy is:

1. Human Project Owner
2. Owner Agent — independent oversight, representation and escalation within OWNER-INT-001
3. GPT-5.6 Luna — Chief Architect / General Project Director / Chief Auditor
4. Domain Directors
5. Registered Specialist Agents
6. External execution/review systems such as Claude and Copilot, only within their registered role and task permissions

No lower layer may override a higher layer.

The hierarchy does not create human authority for any AI layer.

Operational flow remains `GPT → Director → Specialist`. Owner Agent observes the full controlled system and intervenes only according to the risk-based Owner Intervention Policy.

## 3. Owner Agent Boundary

The Owner Agent represents the Human Project Owner for independent controlled observation, risk assessment and escalation.

It may:
- observe verified project state within its oversight scope;
- collect critical notifications;
- identify Human Project Owner action requirements;
- present status and evidence directly to the Human Project Owner;
- classify risk under OWNER-INT-001;
- request controlled intervention for R3 conditions;
- initiate an R4 Safety Hold only when a predefined critical condition is deterministically satisfied.

It may not:
- stop work merely because of a keyword, phrase, low-risk implementation detail or ordinary task action;
- invent new stop conditions;
- convert R0-R2 risk into Safety Hold without a verified policy condition;
- grant or expand permissions;
- approve protected actions on behalf of the Human Project Owner;
- alter governance;
- override deterministic Control;
- clear or bypass Security blocks;
- activate itself or another agent;
- reset conflict lineage or extend the three-round limit;
- directly mutate protected Core or production resources.

Risk detection and stop authority are separate decisions: `RISK != STOP`.

## 4. GPT Authority Boundary

GPT-5.6 Luna is the central project orchestration, architecture and verification layer.

GPT may:
- define and coordinate controlled tasks;
- assign work to registered domain directors/agents within verified permission boundaries;
- integrate results;
- perform independent verification;
- stop unsafe, contradictory or unverifiable progression when applicable control conditions require it;
- prepare controlled next actions.

GPT may not:
- create Human Project Owner authority;
- bypass deterministic Control;
- silently override governance;
- grant unrestricted permissions;
- extend the three-round conflict limit;
- convert missing evidence into PASS.

## 5. Domain Director Boundary

A Domain Director owns operational coordination inside one defined domain.

Initial capability slots may include:
- Security
- Architecture
- Engineering
- Data / Database
- QA / Verification
- DevOps / Infrastructure
- AI Orchestration
- Product / UX

A capability slot may remain RESERVED / NOT ACTIVE when its contract, permission or tools are not verified.

A Domain Director may:
- decompose an assigned task within its domain;
- request registered specialist agents;
- collect their results;
- perform domain-level synthesis;
- return one governed handoff to GPT.

A Domain Director may not:
- command another domain directly;
- alter another domain's permissions;
- bypass GPT verification;
- activate an unverified agent;
- create authority through consensus;
- reopen a terminal conflict.

## 6. Specialist Agent Boundary

A Specialist Agent performs a bounded technical task.

Every specialist must have:
- unique agent identity;
- registered role;
- explicit scope;
- permission profile;
- tool profile;
- lifecycle state;
- task identity;
- evidence requirements;
- canonical handoff location.

Agent availability or model capability does not itself create permission.

## 7. Delegation Rule

Delegation is strictly downward.

`Human Owner → Owner Agent → GPT → Domain Director → Specialist Agent`

A Specialist Agent may not independently delegate to another Specialist Agent.

A Domain Director may request another domain's participation only through GPT-controlled task routing.

No agent may create an autonomous delegation chain.

## 8. Communication Rule

Free-form agent-to-agent conversation is prohibited for controlled work.

Communication must use governed task/result records:

`TASK → ACK → WORK → RESULT → EVIDENCE → GPT VERIFICATION → NEXT CONTROLLED ACTION`

Progress messages, quality checks and risk observations are lifecycle/control events, not problem-solving rounds.

Substantive disagreement belongs to the controlled conflict lineage.

Tool availability, messaging capability or connector access cannot bypass this rule.

## 9. Three-Round Universal Problem-Solving Limit

For one `logical_problem_id`, substantive conflict/problem-resolution is limited to exactly three controlled rounds.

- Round 1: initial analysis/solution.
- Round 2: correction/challenge using permitted new evidence or analysis.
- Round 3: final controlled attempt.
- Round 4+: DENIED.

This limit applies across agents, providers, directors and communication channels.

Changing task ID, agent, provider, conversation, branch or workflow does not reset the lineage.

Execution lifecycle events, risk assessment, QA checks and evidence delivery may continue as required for handoff, verification or safety handling; they are not new conflict rounds.

## 10. Terminal Conflict State

If Round 3 does not produce a verified resolution:

`STOP → BLOCKED / REVIEW_REQUIRED / HUMAN_ACTION_REQUIRED`

No automatic specialist discussion may continue.

The terminal handoff must preserve the logical problem lineage, participants, evidence, findings, unresolved issue, risks and required authority/action.

Reopening requires a deterministic new control event and a materially new problem/evidence state.

## 11. Delegation Depth / Loop Protection

Delegation depth is a protected control dimension.

A task must carry sufficient parent/root lineage to detect recursive delegation.

A maximum operational delegation depth must be explicitly configured and independently verified before delegated sub-agent execution is activated.

If the depth limit is missing, invalid or unverifiable, delegated sub-agent execution is DENIED rather than guessed.

No agent may increase, reset or bypass the depth limit.

## 12. Terminal Task States

Every controlled task must eventually resolve to a governed terminal or escalation state, including:

- `COMPLETED`
- `BLOCKED`
- `REVIEW_REQUIRED`
- `HUMAN_ACTION_REQUIRED`
- `STOPPED`

A terminal task cannot automatically recreate itself or reopen its own unresolved work.

## 13. Security Independence

Security is an independent control domain.

The Security Director/Agent may block unsafe work within its verified policy scope.

Implementation agents may not suppress, rewrite or bypass a security block to obtain PASS.

Security agents may not remove their own restrictions or grant themselves authority.

Security policy changes require the applicable governance and Human Project Owner process.

## 14. Agent Lifecycle

Canonical lifecycle remains:

`PROPOSED → REGISTERED → ACTIVE → SUSPENDED / REVOKED`

Only `ACTIVE` agents may receive operational controlled tasks.

Creation, activation, suspension and revocation are governed changes and cannot be performed unilaterally by the affected agent.

## 15. Capability Gaps

An unavailable capability shall remain a controlled gap rather than be simulated by an unverified agent.

A RESERVED / NOT ACTIVE capability is valid project state.

Activation of a future capability requires:

`REGISTRATION → PERMISSION → TOOL PROFILE → CONTROL TEST → SECURITY REVIEW → ACTIVATION`

This allows future expansion without redesigning the authority hierarchy.

## 16. Extension Without Architectural Reset

New domains and specialist capabilities shall attach beneath GPT through the existing Director/Agent contracts.

New capabilities must not modify the constitutional hierarchy, task identity model, result gate or conflict lineage merely to become operational.

New quality or security gates must attach through explicit risk-based intervention policy and must not become unrestricted continuous blockers.

If a proposed capability cannot fit safely within the existing model, it remains BLOCKED / ARCHITECTURE GAP until a controlled governance change is approved.

## 17. No-Debt Rule

No agent may introduce a shortcut that weakens identity, authority, lineage, evidence, security, reproducibility or auditability.

Temporary scaffolding is acceptable only when explicitly non-authoritative, bounded and removable without changing the permanent control model.

An empty capability branch is preferred to an unsafe temporary authority path.

## 18. Fail-Closed Conditions

The relevant protected action must stop when any required hierarchy, identity, scope, permission, task, lineage, evidence, security or authority value is missing, stale, conflicting, malformed or unverifiable.

Normal low-risk work must not be stopped solely because risk information is incomplete when no protected action is being attempted.

The system must never interpret unavailable control information as permission for a protected action.

## 19. Required Runtime Controls

This architecture is not considered runtime-enforced until real evidence exists for at least:

- hierarchy/role binding;
- downward-only delegation;
- delegation lineage;
- configured depth enforcement;
- universal three-round lineage enforcement;
- counter-reset rejection;
- terminal conflict closure;
- terminal task non-reopening;
- risk-based Owner Agent intervention thresholds;
- context-aware false-positive protection;
- Security block independence;
- capability activation gates;
- auditability of protected actions.

Until then, these remain controlled design requirements and must not be reported as runtime PASS.

## 20. Acceptance Criteria

AGOV-01: Human Project Owner remains the highest authority.
AGOV-02: Owner Agent cannot create or exercise human authority.
AGOV-03: GPT remains the central orchestration/architecture/verification layer.
AGOV-04: Domain Directors are bounded to their domains.
AGOV-05: Specialist agents cannot freely delegate or create autonomous chains.
AGOV-06: Controlled communication follows task/result records.
AGOV-07: Substantive problem solving is limited to three rounds per logical problem.
AGOV-08: Round 4 and counter-reset attempts are denied.
AGOV-09: Terminal conflicts cannot automatically reopen.
AGOV-10: Delegation depth is fail-closed when unconfigured or unverifiable.
AGOV-11: Security blocking remains independently protected.
AGOV-12: Owner Agent intervention is risk-based and context-aware rather than keyword-driven.
AGOV-13: R0-R2 conditions do not automatically create Safety Hold.
AGOV-14: R4 Safety Hold requires a predefined critical condition.
AGOV-15: Future capabilities can be added without changing the constitutional hierarchy.
AGOV-16: Missing capabilities may remain controlled empty branches.
AGOV-17: No-debt and fail-closed principles remain binding.

## 21. Current State

CONTROLLED DESIGN BASELINE.

This document defines the target architecture. Runtime enforcement is not claimed until the listed controls have been independently implemented and evidenced.
