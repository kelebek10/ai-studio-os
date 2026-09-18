# AI WORKER PROFILES

## Purpose

This file is the operational workforce-management layer for GPT-5.6 Luna. AI/Agent assignments must be based on observed execution evidence, not nominal model reputation.

## Binding Operating Principle

**Kimin neyi, nasıl ve ne kadar yapabildiğini bil; görevi buna göre ver.**

A worker profile is operational evidence, not a personality judgment and never grants authority.

## Worker Profile Dimensions

For every AI/Agent, maintain evidence for:
- Task fit: which task classes it demonstrably handles well.
- Method fit: how much structure, context, decomposition and supervision it needs.
- Capacity: practical task size, session/limit tolerance and closure reliability.
- Evidence discipline: test quality, provenance, PASS/FAIL honesty and handoff quality.
- Runtime capability: actual tools, permissions, network/runtime access and capability gaps.
- Failure modes: recurring technical, procedural or delivery patterns.
- Verification level: independent control required before acceptance.
- Collaboration fit: which agents/tasks combine effectively with it.

No profile field is inferred from model identity alone. Update only from verified tasks, commits, tests, evidence, handoffs and tool/runtime observations.

## Agent Assignment Matrix

Before assigning a substantial task, GPT evaluates:

| Dimension | Question | Assignment consequence |
|---|---|---|
| Task fit | Has this worker successfully done this class of work? | Prefer demonstrated fit; otherwise use controlled POC. |
| Method fit | Does it need decomposition, examples or strict boundaries? | Adjust work order structure. |
| Capacity | Can it close the requested scope in its practical session limits? | Split into smaller tasks when needed. |
| Runtime | Does it actually have required access? | Provide controlled runtime or mark capability gap. |
| Evidence | Can its result be independently verified? | Define evidence requirements before execution. |
| Risk | Is the task security/governance/Core-sensitive? | Increase independent verification; never self-certify. |
| Closure | Does it reliably finish commit + evidence + handoff? | Use smaller closure units if necessary. |
| Collaboration | Which other agent is suited for review/implementation? | Separate implementer and verifier where required. |

### Assignment rule

**Right worker + right task size + right boundary + right evidence requirement + right verification level.**

## Current Observed Profile — Claude

Evidence source: Bridge Runtime v1 work on branch feature/comm-bridge-runtime-v1.

- Strong task fit: governance synthesis, contract writing, focused control-logic implementation, explicit capability-gap reporting.
- Evidence discipline: generally distinguishes algorithm/unit-level PASS from real runtime/criterion PASS; no observed unsupported PASS in the verified work.
- Method fit: performs better with small, explicit, bounded, closable work packages.
- Capacity pattern: long sessions and large bundled deliverables reduce closure efficiency; implementation/evidence/commit/handoff often reaches the session limit late in the task.
- Runtime limitation observed: direct access to controlled PostgreSQL/runtime infrastructure may be unavailable; tasks requiring it must use the controlled runtime path or remain a capability gap.
- Recommended assignment pattern: one task → one commit → evidence → handoff → stop.
- Verification: independent GPT verification remains mandatory for governance/security/runtime claims.

## Agent Onboarding Protocol

When a new AI/Agent joins:

1. Give a bounded pilot task.
2. Observe actual execution, not claims.
3. Record task fit, method fit, capacity, evidence discipline and runtime capability.
4. Give a second task of a different but related class to test consistency.
5. Establish the minimum effective work-order structure.
6. Define required independent verification.
7. Add the worker to the assignment matrix only after evidence exists.

## Continuous Learning Loop

ASSIGN → OBSERVE → VERIFY → PROFILE → ASSIGN BETTER → REVERIFY

A worker profile is never a permanent rating. New evidence may strengthen, weaken or invalidate previous assumptions.

## Universal Control

The universal 3-round rule applies to all AI/Agent work and inspector hierarchy. Agent/provider/session/conversation/branch/workflow changes must not reset the logical problem round count.

## Authority Boundary

This file does not grant authority. Authority remains defined by project governance contracts. Implementers cannot self-approve security/governance/runtime-critical results.

## Review Trigger

Before each substantial assignment, GPT should explicitly determine:
- What has this worker demonstrably done well?
- What failure/limit pattern is known?
- What task size and instruction structure fits?
- What runtime/tool access is actually available?
- What evidence must be produced?
- What independent verification is required?

After completion, update the profile only when new evidence materially changes the operational understanding.
