# PAI-FORGE — PostgreSQL Schema Revision Order

**Document:** POSTGRESQL-SCHEMA-REVISION-ORDER-v1.1.md  
**Version:** 1.1  
**Status:** CONTROLLED REVISION PLAN  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`

## Purpose

Extend the approved v1.0 revision order so the PostgreSQL blueprint can enforce the Constraint & Conflict Resolution Contract v1.1 without prematurely implementing the full Design State or Change Request application contracts.

This document is a planning/control artifact. It does not authorize production migration.

## Dependency Order

| Step | Control Area | Prerequisite | Gate |
|---|---|---|---|
| 1 | Existing core write authority / tenant / FK foundations | Existing v1.1 controls | Foundation preserved |
| 2 | Constraint + immutable Constraint Version | Identity and provenance controls | Versioned constraints enforceable |
| 3 | Design State snapshot/version/hash boundary | Entity identity + immutability | State-bound evaluation possible |
| 4 | Impact / Dependency records | Constraint + Design State | Dependency analysis traceable |
| 5 | Feasibility Evaluation + ruleset/provenance | Impact / Dependency | Deterministic feasibility traceable |
| 6 | Conflict bound to Design State + constraint versions | Steps 2–5 | Conflict cannot float across states |
| 7 | Alternative separate from evaluation | Conflict + feasibility | Alternatives auditable |
| 8 | Resolution immutability | Conflict + Alternative | Resolution cannot be rewritten |
| 9 | Approval Event append-only ledger | Resolution + authorization | Approval cannot mutate history |
| 10 | Candidate / Verified / Approved boundary | Proposal/evidence controls | Unapproved data cannot enter Core |
| 11 | Change Request boundary + stale-state/idempotency controls | Design State + approval/event model | Replay/stale mutation blocked |
| 12 | Cross-model provenance + immutable Core identity references | All prior controls | Full audit chain preserved |
| 13 | Query/index hardening | Final structural schema | Access paths justified |

## Explicit Non-Goals for v1.2

- No full Design State application contract.
- No full Change Request state machine.
- No production SQL migration.
- No data import.
- No infrastructure mutation.
- No LLM authority over deterministic feasibility, conflict blocking, priority, or approval transitions.

## Mandatory Invariants

1. Constraint versions are immutable.
2. Design State versions are immutable snapshots.
3. Conflict records bind to an exact Design State version/hash and relevant Constraint Versions.
4. Feasibility evaluations record deterministic ruleset/engine provenance.
5. PARTIALLY_FEASIBLE cannot auto-apply.
6. Resolution is immutable after creation.
7. Approval history is append-only.
8. Candidate, Verified, Approved and Active states remain distinguishable.
9. Change Requests cannot apply against a stale Design State.
10. Deterministic idempotency prevents duplicate application of the same canonical request.
11. Core identity references are immutable and never reused.
12. No alternate write path may mutate an existing Design State version.

## Review Gate

The resulting PostgreSQL Blueprint v1.2 must be reviewed against this order and the existing Schema Review Checklist before migration design is authorized.

**Production migration remains BLOCKED.**
