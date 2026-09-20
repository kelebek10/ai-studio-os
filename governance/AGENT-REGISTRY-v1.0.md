# PAI-FORGE — AGENT REGISTRY v1.0

Document ID: AGENT-001
Version: 1.0
Status: CONTROLLED DESIGN BASELINE
Branch: phase-1-3-foundation
Owner: Human Project Owner
Parent: AI-OPS-001
Constitutional Control: PAI-FORGE-001A
Task Contract: TASK-001
Result Gate: AI-RHG-001

## 1. Purpose

Define the authoritative registry for AI agents permitted to participate in controlled PAI-FORGE work.

An agent is operationally recognized only when its identity, role, scope, lifecycle state and permission profile are registered and verified.

The registry grants identity and role classification. It does not independently grant tool permissions, human authority, production access or Core write authority.

## 2. Registry Record

Every registered agent shall have, at minimum:

- `agent_id`
- display name
- model/provider
- role
- owner
- project scope
- allowed task classes
- permission profile reference
- tool access profile reference
- lifecycle status
- version
- registration timestamp
- governance references

Registry records must be uniquely identifiable and versioned.

## 3. Lifecycle States

Canonical agent states:

- `PROPOSED` — candidate definition; not operational.
- `REGISTERED` — identity and scope recorded; activation still requires applicable controls.
- `ACTIVE` — eligible to receive tasks within its permission profile.
- `SUSPENDED` — temporarily prevented from receiving new controlled tasks.
- `REVOKED` — no longer eligible for controlled work.

A non-ACTIVE agent must not be treated as operational.

## 4. Initial Registered Agents

### AGENT-CLAUDE-001

- Agent ID: `AGENT-CLAUDE-001`
- Name: Claude
- Provider: Anthropic
- Role: Controlled Operations / Builder / Technical Reviewer
- Owner: Human Project Owner
- Project scope: PAI-FORGE
- Repository scope: `kelebek10/ai-studio-os`
- Development branch boundary: `phase-1-3-foundation`
- Lifecycle status: `ACTIVE`
- Permission profile: `PENDING — PERMISSION-001`
- Tool access profile: `PENDING — TOOL-001`
- Boundary contract: `CLAUDE-PAIFORGE-OPERATING-BOUNDARY-v1.0`

Claude may inspect, implement, test, review and prepare handoffs only within an assigned task and its verified permission profile. Its existing operating boundary remains binding.

### AGENT-GPT-001

- Agent ID: `AGENT-GPT-001`
- Name: GPT-5.6 Luna
- Provider: OpenAI
- Role: Project Orchestration / Architecture / QA Coordination
- Owner: Human Project Owner
- Project scope: PAI-FORGE
- Lifecycle status: `ACTIVE`
- Permission profile: `PENDING — PERMISSION-001`
- Tool access profile: `PENDING — TOOL-001`

GPT coordinates controlled task flow and independently verifies material AI handoffs. It does not create Human Project Owner authority and does not bypass deterministic controls.

### AGENT-GEMINI-001

- Agent ID: `AGENT-GEMINI-001`
- Name: Gemini
- Provider: Google
- Role: Independent Specialist / Consortium Reviewer
- Owner: Human Project Owner
- Project scope: PAI-FORGE
- Lifecycle status: `REGISTERED`
- Permission profile: `PENDING — PERMISSION-001`
- Tool access profile: `PENDING — TOOL-001`

Gemini is not an orchestration authority and cannot promote its own findings to authoritative project state.

### AGENT-COPILOT-001

- Agent ID: `AGENT-COPILOT-001`
- Name: Copilot
- Provider: GitHub / Microsoft
- Role: Independent Specialist / Consortium Reviewer
- Owner: Human Project Owner
- Project scope: PAI-FORGE
- Lifecycle status: `REGISTERED`
- Permission profile: `PENDING — PERMISSION-001`
- Tool access profile: `PENDING — TOOL-001`

Copilot is not an orchestration authority and cannot promote its own findings to authoritative project state.

### AGENT-KIMI-001

- Agent ID: `AGENT-KIMI-001`
- Name: Kimi
- Provider: Moonshot AI
- Role: Independent Specialist / Consortium Reviewer
- Owner: Human Project Owner
- Project scope: PAI-FORGE
- Lifecycle status: `REGISTERED`
- Permission profile: `PENDING — PERMISSION-001`
- Tool access profile: `PENDING — TOOL-001`

Kimi is not an orchestration authority and cannot promote its own findings to authoritative project state.

## 5. Security Agent

The Security Agent is a required future registered control role.

It shall remain independently governed and shall not be subordinate to the implementation coordinator for its blocking authority.

It is intentionally not marked `ACTIVE` in this v1.0 registry until its Security Agent Contract and Permission Model are independently verified.

## 6. Registration Rules

An agent cannot become operational merely because a model, connector or API can instantiate it.

Before activation, the following must be verified:

1. unique identity;
2. project scope;
3. role and task class;
4. permission profile;
5. tool access profile;
6. applicable security contract;
7. task/handoff compatibility;
8. owner and lifecycle state;
9. governance compatibility.

Missing verification means the agent remains `REGISTERED`, `PROPOSED` or `SUSPENDED`, as applicable.

## 7. Authority Boundary

Registration never grants:

- Human Project Owner authority;
- human approval capability;
- unrestricted GitHub access;
- production access;
- protected Core mutation;
- permission self-escalation;
- governance policy modification;
- authority to activate another agent without the applicable control.

Agent consensus is not authority.

## 8. Task Assignment Boundary

Only an `ACTIVE` agent may receive an operational controlled task.

Every assignment must bind to:

- agent ID;
- task ID;
- correlation ID;
- current source state;
- task scope;
- permission profile;
- evidence requirements;
- canonical handoff location.

The assigned agent must acknowledge that task context before execution where the runtime supports acknowledgement.

## 9. Suspension / Revocation

An agent shall be suspended or revoked when required by security, governance, permission, provenance, integrity or repeated control failure.

Suspension/revocation must not delete historical evidence. Existing task records remain traceable to the agent identity and registration version.

## 10. Change Control

Changes to agent identity, role, scope, lifecycle state, permission profile or tool profile are governed changes.

No agent may unilaterally modify its own registry record or activate itself.

A registry change must be independently checked against the current governance state before becoming operational.

## 11. Acceptance Criteria

AGENT-01: Every operational agent has a unique identity.

AGENT-02: Role and project scope are explicit.

AGENT-03: Lifecycle status is explicit and prevents implicit activation.

AGENT-04: Permission and tool access remain separate from registration.

AGENT-05: Claude's existing project boundary remains binding.

AGENT-06: No registered agent can create Human Project Owner authority or self-escalate.

AGENT-07: Task assignment can be traced to a registered agent and canonical task record.

AGENT-08: Unverified Security Agent capability cannot be represented as active authority.

## 12. Current State

This is a controlled design baseline. Permission Model and Tool Access Policy remain pending. Runtime enforcement of registry state, automatic task dispatch and agent acknowledgement require separate implementation and real evidence.
