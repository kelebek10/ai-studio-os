# PEYZAJ AI / PAI-FORGE — CONSTRAINT & CONFLICT RESOLUTION STANDARD

**Document:** `CONSTRAINT-CONFLICT-RESOLUTION-STANDARD.md`  
**Version:** 1.1  
**Status:** PROPOSED  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`  
**Production Implementation:** BLOCKED  
**Database Migration:** BLOCKED

## 1. Purpose & Scope

This standard governs conflicts between requested actions and design constraints, safety rules, scientific/engineering requirements, and other design conditions. It requires deterministic conflict detection, explicit safe alternatives, attributable approval where required, immutable Design State history, and traceable provenance. It does not approve production implementation or PostgreSQL migration.

## 2. Object Model

Core objects are distinct: `ACTION`, `CONSTRAINT`, `PREFERENCE`, `GOAL`, `IMPACT_DEPENDENCY`, `FEASIBILITY_EVALUATION`, `CONFLICT`, `ALTERNATIVE`, `RESOLUTION`, `APPROVAL_EVENT`, `DESIGN_STATE`, `CHANGE_REQUEST`.

`ACTION` is not a constraint. `ALTERNATIVE` is not a feasibility evaluation. `APPROVAL_EVENT` is not merely a mutable status field.

## 3. Constraint Classification

Allowed classifications:

- `SAFETY_ENGINEERING`
- `CUSTOMER_HARD`
- `CUSTOMER_GOAL`
- `PREFERENCE`
- `OPTIMIZATION`
- `AESTHETIC`

Classification does not by itself determine enforcement; mapping is controlled separately.

## 4. Enforcement Model

Allowed enforcement values:

- `NON_NEGOTIABLE`
- `HARD`
- `SOFT`
- `INFORMATIONAL`

`NON_NEGOTIABLE` is reserved for conditions that cannot be violated. `HARD` blocks automatic application until satisfied. `SOFT` may be changed with explicit handling. `INFORMATIONAL` does not directly block a decision.

## 5. Deterministic Priority Model

Priority order:

1. `P0` — Safety / validated scientific-engineering non-negotiables
2. `P1` — Explicit customer hard constraints
3. `P2` — Customer goals and preferences
4. `P3` — Optimization objectives
5. `P4` — Aesthetic optimization

An `ACTION` never outranks a higher-priority hard constraint.

## 6. Classification / Enforcement / Priority Mapping

The tuple `(classification, enforcement, priority)` is versioned and validated deterministically. Invalid tuples resolve to `REQUIRES_REVIEW`.

| Classification | Valid Enforcement | Default Priority |
|---|---|---|
| `SAFETY_ENGINEERING` | `NON_NEGOTIABLE`, `HARD` | P0 |
| `CUSTOMER_HARD` | `HARD` | P1 |
| `CUSTOMER_GOAL` | `SOFT`, `INFORMATIONAL` | P2 |
| `PREFERENCE` | `SOFT`, `INFORMATIONAL` | P2 |
| `OPTIMIZATION` | `SOFT` | P3 |
| `AESTHETIC` | `SOFT`, `INFORMATIONAL` | P4 |

LLM or runtime user input cannot change this mapping.

## 7. Constraint Versioning & Immutability

Constraint identity remains stable across versions. A changed constraint creates a new version; historical versions are never overwritten. Historical evaluations and resolutions remain reconstructible against the exact constraint version used.

## 8. Constraint Evidence Requirements

Every constraint requires provenance including source, evidence where applicable, creator, creation time, validator, and validation time.

For `SAFETY_ENGINEERING + NON_NEGOTIABLE`, validated evidence is mandatory. Without evidence the system cannot enforce the constraint as non-negotiable and must route to `REQUIRES_ENGINEERING_REVIEW`.

## 9. ACTION Interface

Minimum conceptual fields: `action_id`, `action_type`, `source`, `requested_change`, `target`, `created_at`, `created_by`, `base_design_state_id`, `base_design_state_version`.

An action cannot override constraints or alter their priority.

## 10. Impact / Dependency Interface

Each relevant change must identify affected objects, dependent objects, impact/dependency type, blocking status, evaluation basis, and provenance. HARD-constraint changes cannot be automatically applied before required impact/dependency evaluation.

## 11. Feasibility Evaluation

Allowed results:

- `FEASIBLE`
- `INFEASIBLE`
- `PARTIALLY_FEASIBLE`
- `REQUIRES_REVIEW`

Evaluation must bind to the exact Design State version, constraint versions, relevant impact/dependency context, and deterministic ruleset version. `PARTIALLY_FEASIBLE` cannot be auto-applied.

## 12. CONFLICT Object

A conflict records an action/constraint incompatibility. Minimum conceptual references: `conflict_id`, `action_id`, `design_state_id`, `design_state_version`, `design_state_hash`, constraint IDs and versions, conflict type, severity, blocking status, reason, evidence/evaluation references, and creation time.

A conflict cannot silently migrate to another Design State version.

## 13. ALTERNATIVE Object

An alternative is a proposed change intended to resolve or reduce a conflict. It is not an applied change and not a feasibility result. Each alternative requires independent feasibility evaluation and must preserve all applicable hard/non-negotiable constraints.

## 14. RESOLUTION Object

Allowed resolution outcomes:

- `FEASIBLE`
- `BLOCKED`
- `ALTERNATIVES_AVAILABLE`
- `REQUIRES_CUSTOMER_DECISION`
- `REQUIRES_ENGINEERING_REVIEW`

Resolution records are immutable. A later evaluation creates a new resolution rather than overwriting history.

## 15. Resolution Lifecycle

`ACTION → IMPACT/DEPENDENCY → FEASIBILITY → CONFLICT DETECTION → RESOLUTION → PROPOSED CHANGE → APPROVAL → DESIGN STATE UPDATE`

A proposed change cannot become active without the required approval.

## 16. Approval Event & Authorization

Approval is an append-only attributable event. Minimum concepts: approval event ID, target/change request, approved version, decision, principal, authorization context, timestamp, and supporting reference.

Raw free text or an LLM interpretation alone is not a formal approval record.

## 17. Design State Boundary

Design State versions are immutable and traceable. New states are created as successor versions. An action evaluated against an older state cannot silently mutate a newer state.

## 18. Change Request Boundary

A Change Request carries a controlled proposed change from an action/conflict toward approval. Minimum interface: `change_request_id`, source action/conflict, base Design State version, requested change, and approval state. Full Change Request schema is a separate governance dependency.

A Change Request cannot directly mutate Design State.

## 19. Idempotency & Replay Protection

Repeated identical requests must not create duplicate evaluations, change requests, or Design State mutations. Idempotency is based on a canonical representation and deterministic idempotency key including the relevant Design State version/hash, constraint versions, request identity, and deterministic ruleset version. Exact replays return/reference the existing result.

## 20. Staleness & Concurrency

A request whose base Design State is no longer current is stale. It must be re-evaluated or rejected. A decision evaluated against version N cannot silently mutate version N+1. Physical concurrency mechanisms belong to the PostgreSQL Blueprint.

## 21. Candidate / Verified / Approved Boundary

AI-generated records remain distinct from verified and approved state. Minimum conceptual lifecycle: `CANDIDATE → VERIFIED → APPROVED → ACTIVE`. LLM output does not become verified or approved automatically.

## 22. Deterministic vs LLM Authority

Deterministic logic is authoritative for classification validation, priority mapping, feasibility, blocking, conflict/resolution status, approval transitions, version consistency, idempotency, staleness, and constraint integrity.

LLMs may extract intent, generate candidates, suggest alternatives, and explain results, but cannot override safety/hard constraints, approve changes, mutate Design State, or write Core directly. LLM outputs require deterministic re-validation.

## 23. Provenance & Audit Chain

Critical decisions must be traceable through:

`CORE STATE → DESIGN STATE → APPROVAL EVENT → CHANGE REQUEST → RESOLUTION → CONFLICT → FEASIBILITY EVALUATION → CONSTRAINT VERSION → EVIDENCE/SOURCE`

Critical predecessor relationships must remain explicitly traceable.

## 24. Invalidation & Supersession

Upstream version changes may make downstream evaluations or resolutions stale, superseded, or invalidated. Historical records are never deleted for this purpose. Re-evaluation follows upstream changes. Invalidation is non-destructive.

## 25. Core Write Boundary

Core mutation requires validated constraints, deterministic evaluation, conflict resolution, required approval, current-state validation, provenance, and auditability. No AI model or automation workflow may directly mutate Core. n8n has no Core write authority without a separately approved governance/security decision.

## 26. Required Test Matrix

Minimum tests:

1. Single hard conflict
2. Multiple hard conflict
3. Safety vs customer hard
4. Safety vs safety
5. Customer hard vs customer hard
6. Hard vs soft
7. Action vs constraint
8. Feasible alternative
9. No feasible alternative
10. Customer decision required
11. Silent trade-off prevention
12. Repeated Change Request / idempotency
13. Design State version mismatch
14. Constraint version supersession
15. Missing safety evidence
16. Candidate vs verified boundary
17. LLM deterministic re-validation
18. Approval authorization
19. PARTIALLY_FEASIBLE non-auto-apply
20. No alternate Design State mutation path

`GEOMETRY CONFLICT TEST 002` is a reference behavioral test for this standard.

## 27. Governance Status

**Status: PROPOSED.** This document does not approve production implementation or PostgreSQL migration. Required review path: Claude architecture/governance review, Gemini data/schema review, GPT-5.6 Luna reconciliation, Human Project Owner approval.

## 28. Open Dependencies

Required dependencies:

- Design State Contract
- Change Request Contract
- Impact / Dependency Contract
- Evidence / Provenance Contract
- PostgreSQL Schema Blueprint

Related dependencies include Identity Model, Zone Model, Zone Scope Data Contract, and Approval/Authorization Model.

## 29. Core Governance Invariants

- A hard constraint cannot be silently weakened.
- A non-negotiable safety constraint requires validated evidence.
- An action cannot outrank a hard constraint.
- An alternative is not an applied change.
- A feasibility result is not an approval.
- An approval is an attributable governance event.
- A stale decision cannot silently mutate a newer Design State.
- Historical resolutions remain reconstructible.
- LLM output cannot bypass deterministic validation.
- No alternate Design State mutation path is permitted.
- Safety conflicts requiring expert judgment route to engineering review.
- `PARTIALLY_FEASIBLE` results cannot be automatically applied.

## 30. Approval Gate

`PROPOSED → AUDITED → RECONCILED → HUMAN APPROVED → IMPLEMENTATION READY`

Human Project Owner approval is required before production implementation, PostgreSQL migration, or automatic Design State mutation.

---

**END OF STANDARD v1.1**
