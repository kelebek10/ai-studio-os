# PAI-FORGE — Owner Agent Intervention Policy v1.0

Document ID: OWNER-INT-001
Version: 1.0
Status: CONTROLLED DESIGN BASELINE
Branch: phase-1-3-foundation
Owner: Human Project Owner
Parent: AGENT-GOV-001
Constitutional Control: PAI-FORGE-001A

## 1. Purpose

Define when the Owner Agent observes, reports, requests intervention, or places a controlled Safety Hold without turning normal project work into continuous approval bureaucracy.

## 2. Core Rule

Risk detection and stop authority are separate decisions.

`RISK != STOP`

A keyword, phrase, code token, hypothetical example, documentation text, or ordinary task action is not a risk by itself. Risk assessment must consider context, task scope, actual effect, authority, target environment and protected-resource impact.

## 3. Risk Levels

- R0 NORMAL: no intervention.
- R1 LOW: observe and record; no interruption.
- R2 MEDIUM: notify the responsible Director/QA; work may continue unless another verified control requires a pause.
- R3 HIGH: controlled intervention; affected operation may be paused pending GPT/Director review.
- R4 CRITICAL: Safety Hold for the affected operation; escalate to GPT/Security and Human Project Owner when required.

## 4. Intervention Authority

Owner Agent may:
- observe the full controlled system within its verified read/oversight scope;
- classify or report risk according to the verified intervention policy;
- issue R3 controlled-intervention requests;
- initiate R4 Safety Hold only when a predefined Safety Hold condition is deterministically satisfied;
- directly notify the Human Project Owner of critical events and required human action;
- preserve and present evidence.

Owner Agent may not:
- stop work merely because it dislikes a word, phrase, implementation choice or low-risk action;
- create new risk categories ad hoc;
- convert R0-R2 into a Safety Hold without a verified policy condition;
- grant or expand permissions;
- approve protected actions on behalf of the Human Project Owner;
- clear or bypass Security/Control blocks;
- alter governance or policy;
- reset conflict lineage or extend the three-round limit;
- directly mutate protected Core or production resources.

## 5. Context Requirement

Risk evaluation must consider at minimum:
- task identity and scope;
- actor/agent identity and permission;
- requested or actual action;
- target resource and environment;
- expected and observed effect;
- evidence/provenance;
- applicable policy version;
- whether the condition is reversible;
- whether a protected boundary is crossed.

A matching keyword alone is insufficient for intervention.

## 6. Safety Hold Conditions

R4 Safety Hold is reserved for verified conditions such as:
- active or imminent security boundary violation;
- unauthorized protected-resource mutation or attempted execution;
- human-authorization bypass or impersonation;
- provenance/integrity failure affecting a protected decision;
- deterministic Control/authority contradiction affecting a protected action;
- verified governance or permission bypass;
- other explicitly registered critical conditions approved through governance.

Unknown or missing information does not automatically create R4. If the unknown state affects a protected action, the applicable fail-closed control denies that action.

## 7. Escalation

`R0 -> CONTINUE`

`R1 -> OBSERVE / RECORD`

`R2 -> DIRECTOR / QA REVIEW`

`R3 -> CONTROLLED PAUSE / GPT + DOMAIN REVIEW`

`R4 -> SAFETY HOLD -> GPT / SECURITY -> HUMAN ACTION WHEN REQUIRED`

Human approval is required only where the applicable authorization policy explicitly requires it. Owner Agent notification is not human approval.

## 8. False-Positive Protection

The Owner Agent must not block legitimate work because a task contains security-sensitive vocabulary, simulated commands, test fixtures, examples, quoted attacks, or hypothetical operations when the verified context shows no prohibited execution or protected-boundary crossing.

## 9. Recovery

An R3 pause may resume after the responsible control/review path verifies the condition is cleared.

An R4 Safety Hold may be cleared only by the applicable deterministic control and higher-authority process. Owner Agent cannot unilaterally clear its own Safety Hold.

## 10. Conflict Interaction

Risk assessment, progress, evidence delivery and review are lifecycle events, not conflict rounds.

The universal three-round limit applies only to substantive problem-solving for the same `logical_problem_id`.

Owner Agent cannot create a new task, agent, provider, conversation or branch to reset the conflict lineage.

## 11. Fail-Closed Boundary

If a protected action is attempted while required authority, identity, policy, evidence or provenance is missing or unverifiable, the protected action is denied by deterministic Control. Owner Agent must not invent permission or silently convert uncertainty into approval.

## 12. Design Intent

The Owner Agent is a high-level independent oversight mechanism, not a continuous operational gatekeeper. The system should remain productive under R0-R2 conditions and become progressively more restrictive only as verified risk severity increases.

## 13. Acceptance Criteria

OWNER-01: R0-R2 do not automatically create Safety Hold.
OWNER-02: R3 supports controlled intervention without granting arbitrary stop authority.
OWNER-03: R4 Safety Hold requires a predefined critical condition.
OWNER-04: Keyword-only detection cannot stop legitimate work.
OWNER-05: Human approval remains separate from Owner Agent notification.
OWNER-06: Owner Agent cannot alter permissions, governance or conflict limits.
OWNER-07: Risk evaluation is context-aware and policy-bound.
OWNER-08: Protected actions remain fail-closed when required control state is missing.
OWNER-09: Risk assessment does not create additional conflict rounds.
OWNER-10: Policy is extensible through governed additions without redesigning the authority hierarchy.

## 14. Current State

CONTROLLED DESIGN BASELINE. Runtime enforcement is not claimed until implemented and independently evidenced.
