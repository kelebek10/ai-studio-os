# AI WORKER PROFILES

## Purpose

This file is an operational reminder for GPT-5.6 Luna, as project coordinator, to know the observed working characteristics of each AI/Agent and assign work accordingly.

## Binding Principle

Do not assign work to an AI only by nominal capability. Build and continuously update an evidence-based work profile from observed execution.

Track, when evidenced:
- strengths and task fit
- weaknesses and failure modes
- tool/runtime access and capability gaps
- evidence discipline and PASS/FAIL honesty
- instruction granularity required
- session/limit behavior
- delivery and closure behavior
- handoff quality
- need for independent supervision
- collaboration compatibility with other agents

Use these observations to:
1. choose the appropriate AI/Agent for each task;
2. split work into task sizes the agent can reliably close;
3. set the required verification level;
4. anticipate predictable failure/limit patterns;
5. avoid unnecessary context loss and rework;
6. improve the overall AI orchestration system.

## Current Observed Profile — Claude

Evidence source: Bridge Runtime v1 work on `feature/comm-bridge-runtime-v1`.

- Strong: governance synthesis, contract writing, implementation of focused control logic, explicit capability-gap reporting.
- Strong: generally distinguishes algorithm/unit-level PASS from real runtime/criterion PASS; no observed unsupported PASS in the verified work.
- Weakness: long sessions and large bundled deliverables reduce closure efficiency; tends to reach implementation/evidence/commit/handoff stages near session limits.
- Best task pattern: small, explicit, closable work packages — **one task → one commit → evidence → handoff → stop**.
- Runtime limitation observed: direct access to controlled PostgreSQL/runtime infrastructure may be unavailable; do not assign tasks that require unavailable access without providing the controlled runtime path.
- Supervision: independent verification remains mandatory for governance/security/runtime claims.

## Management Rule

Observed behavior is evidence, not personality judgment. Profiles must be updated only from actual work, commits, tests, evidence, handoffs, and verified tool/runtime behavior.

Do not use this file to grant authority. Authority remains defined by the project governance contracts.

## Universal Control

The universal 3-round rule applies to all AI/Agent work and inspector hierarchy. Agent/provider/session/branch/workflow changes must not reset the logical problem round count.

## Review Trigger

Before assigning a substantial task to an AI/Agent, GPT should ask:
- What has this worker demonstrably done well?
- What failure/limit pattern has been observed?
- What task size and instruction structure fits it?
- What runtime/tool access does it actually have?
- What independent verification is required?

After completion, update the profile only when new evidence materially changes the operational understanding.
