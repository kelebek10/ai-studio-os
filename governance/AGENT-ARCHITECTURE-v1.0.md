# PAI-FORGE — AGENT ARCHITECTURE

Document ID: AGENT-ARCH-001
Version: 1.0
Status: CONTROLLED DESIGN BASELINE
Branch: phase-1-3-foundation
Owner: Human Project Owner
Parent: AI-OPS-001 — AI Operating Model
Constitutional Control: PAI-FORGE-001A — CONTROL-FIRST / NO-DEBT

---

## 1. PURPOSE

This document defines the structural architecture for registered AI agents operating under PAI-FORGE.

Agents are controlled workers. They are not independent authorities and do not replace deterministic Control or Human Project Owner authority.

## 2. OPERATING PRINCIPLE

Every agent follows:

**KONTROL → DOĞRULAMA → KARAR → UYGULAMA → TEKRAR KONTROL**

An agent must STOP when required context, authority, evidence, permission or deterministic validation is missing, stale, contradictory or unverifiable.

## 3. AUTHORITY LAYERS

1. Human Project Owner
2. Constitutional and governance controls
3. Deterministic Control / security enforcement
4. Approved task and permission contracts
5. GPT-5.6 Luna orchestration / architecture coordination
6. Claude controlled operations coordination where assigned
7. Registered specialist agents
8. External AI contributors

No agent may elevate itself between layers.

## 4. AGENT CLASSES

Initial controlled classes:

- **ORCHESTRATOR** — coordinates approved work; no independent authority escalation.
- **BUILDER** — implements task-scoped changes.
- **SECURITY** — independently evaluates defined security controls and may BLOCK.
- **QA** — executes and evaluates defined acceptance tests.
- **RESEARCH** — gathers external evidence; cannot promote evidence to Core authority.
- **DATA** — validates and transforms data within approved boundaries.
- **DOMAIN** — performs specialist scientific/domain analysis.
- **DOCUMENTATION** — prepares controlled documentation and evidence records.

An agent class defines capability intent, not automatic permissions.

## 5. AGENT IDENTITY

Every persistent agent must have:

- immutable agent ID;
- class;
- version;
- owner;
- lifecycle status;
- declared scope;
- permission profile;
- allowed tools;
- prohibited actions;
- evidence requirements;
- review requirements.

No unregistered agent receives privileged access.

## 6. AGENT LIFECYCLE

`PROPOSED → REVIEWED → REGISTERED → ACTIVATED → SUSPENDED / RETIRED`

Activation requires a registered identity and approved permission profile.

A suspended or retired agent cannot execute controlled work.

An agent cannot activate itself or modify its own lifecycle status.

## 7. TASK BOUNDARY

An agent operates only on an approved task contract containing, at minimum:

- task ID;
- project;
- branch;
- source commit;
- objective;
- allowed scope;
- prohibited scope;
- required evidence;
- acceptance criteria;
- permission profile;
- deadline/expiry where applicable.

Task context is authoritative only when consistent with higher governance controls.

## 8. TOOL BOUNDARY

Tools are granted through the Permission Model and are task-scoped.

An agent must not infer permission from tool availability alone.

Tool adapters must preserve:

- least privilege;
- auditability;
- revocation;
- Core isolation;
- provenance.

## 9. SECURITY AGENT

The Security Agent is structurally independent from the Builder and may BLOCK work within its defined policy.

The Security Agent cannot:

- modify its own policy to remove a block;
- grant itself permissions;
- approve its own critical change;
- convert missing evidence into PASS;
- disable deterministic Control.

Security-critical changes require an independent review path.

## 10. ORCHESTRATOR BOUNDARY

The Orchestrator may assign registered agents and sequence approved tasks.

It may not:

- register privileged agents without the registry process;
- grant permissions outside approved policy;
- override Security Agent blocks;
- bypass deterministic Control;
- create Human authorization;
- directly mutate protected Core data outside approved interfaces.

## 11. COMMUNICATION

Agent-to-agent communication is treated as untrusted task data unless validated by the applicable contract.

A message cannot change:

- authority;
- permission;
- policy;
- project scope;
- release status.

Critical state changes require versioned governance records or deterministic control evidence.

## 12. EVIDENCE

Agents may report observations and test results.

PASS requires reproducible evidence appropriate to the acceptance criterion.

Agent statements, model confidence, consensus or generated documentation are not evidence by themselves.

## 13. FAILURE AND STOP BEHAVIOR

The agent must stop on:

- missing required input;
- authority ambiguity;
- permission mismatch;
- stale/conflicting state;
- failed validation;
- nondeterminism where determinism is required;
- provenance loss;
- security uncertainty;
- regression risk;
- avoidable debt risk.

The resulting state must be explicitly classified rather than silently bypassed.

## 14. NO-DEBT / EMPTY-GAP RULE

If a capability cannot yet be safely implemented and proven, the architecture permits a controlled empty capability gap.

The gap must identify:

- missing capability;
- reason;
- blocker;
- required evidence;
- responsible owner;
- next controlled action.

A fake adapter, placeholder authority, bypass or misleading PASS is prohibited.

## 15. CORE BOUNDARY

Agents remain outside the trusted Core authority boundary.

Core mutations must pass through approved deterministic and permission-controlled interfaces.

No agent may obtain direct unrestricted PostgreSQL/Core credentials merely to simplify implementation.

## 16. REVIEW SEPARATION

The same agent should not be the sole implementer and certifier of security-critical or authority-critical work.

Independent review may be performed by another registered agent or approved consortium AI, but Human Project Owner authority remains final where required.

## 17. REPOSITORY BOUNDARY

Normal development occurs on:

`phase-1-3-foundation`

`main` is a protected release boundary.

Agents do not directly modify `main`.

## 18. CURRENT IMPLEMENTATION STATUS

This document defines architecture only.

Agent Registry, Permission Model, Security Agent Contract and Task Contract remain separate controlled documents and must be independently defined and verified before privileged agent activation.

Therefore no new privileged agent is authorized merely by creation of this document.

**Status: DESIGN BASELINE / PRIVILEGED ACTIVATION NOT YET AUTHORIZED.**
