# PAI-FORGE — PostgreSQL Schema Review Checklist

**Document:** POSTGRESQL-SCHEMA-REVIEW-CHECKLIST-v1.0.md  
**Version:** 1.0  
**Status:** CONTROLLED REVIEW CHECKLIST  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`

## 1. Purpose

This checklist converts the 11 approved schema-revision findings into objective PASS/FAIL gates for PostgreSQL Schema Blueprint v1.1.

This document authorizes review only. It does **not** authorize SQL migration, production database mutation, data import, or infrastructure change.

## 2. PASS / FAIL Rules

- **PASS:** The blueprint defines an enforceable PostgreSQL mechanism, its scope, and the required security boundary.
- **FAIL:** The rule exists only as prose, is ambiguous, or can be bypassed by an application/AI/n8n role.
- **BLOCKED:** A prerequisite is unresolved; the dependent control cannot be considered passed.
- All 11 controls must PASS before SQL migration design is authorized.

## 3. Mandatory Checks

| Step | Control | PostgreSQL enforcement required | PASS criterion | FAIL / BLOCK condition |
|---|---|---|---|---|
| 1 | C-16/C-32 Core write authority | Direct table mutation denied to app/AI/n8n roles; controlled service functions/workflows are the only Core mutation path | Roles, GRANT/REVOKE boundary and controlled transition mechanism are explicit | Any unrestricted Core INSERT/UPDATE/DELETE path remains |
| 2 | C-25 Tenant RLS | `tenant_id` contract, FK, ENABLE/FORCE RLS, explicit policies, transaction tenant context, cross-tenant protection | Every tenant-scoped table has enforceable isolation and global identity cannot be tenant-mutated | RLS is described but policy/context/bypass behavior is unspecified |
| 3 | C-30 FK / ON DELETE | Every FK names explicit `ON DELETE` behavior | Each relationship has documented RESTRICT/NO ACTION/CASCADE semantics justified by history | Any FK relies on an unspecified/default deletion behavior |
| 4 | C-05/C-12/C-22/C-23 Immutability | INSERT-only roles, revoked UPDATE/DELETE/TRUNCATE, ownership/trigger/function boundary where needed | Approval, evidence, RAW, and provenance fields cannot be altered by operational writers | Append-only depends only on application convention |
| 5 | C-02 Event sequence | Explicit sequence scope, uniqueness, transaction-safe monotonic allocation | Event ordering cannot collide or be duplicated within its defined aggregate/history scope | Global/per-entity scope is ambiguous or allocation is race-prone |
| 6 | C-03 Idempotency | Explicit uniqueness scope and request/workflow identity | Duplicate operation is rejected deterministically within the defined scope | `idempotency_key` exists without a precise uniqueness domain |
| 7 | C-31 Required fields | Explicit NOT NULL contract for all mandatory identity, provenance, state and relationship fields | Required fields are enumerated table-by-table | Blueprint uses vague “required fields” language |
| 8 | C-09/C-10 Relationship type | ENUM/CHECK controlled vocabulary plus unique relationship constraint | Invalid relationship types are rejected at DB level and duplicates are impossible | Relationship type remains free-form |
| 9 | C-20/C-21 Canonicalization | Persist ruleset version, deterministic canonical key, input fingerprint and collision/review state | Same normalized input under same ruleset is deterministic; collision never auto-merges | Collision behavior is only procedural prose |
| 10 | C-05/C-17/C-18 Proposal → Approval | Proposal fingerprint uniqueness, explicit proposal→approval reference, controlled approval transition, no direct Core write | Approval can be traced to proposal and cannot itself bypass Core workflow | Proposal status can mutate Core directly or traceability is ambiguous |
| 11 | Query/index hardening | Indexes tied to concrete access paths, FK/RLS predicates and uniqueness | Each required index has a stated query/security/constraint purpose | Speculative or missing critical indexes remain |

## 4. Related Hardening Checks

The following are mandatory supporting checks during the same re-review:

1. Knowledge state uses an explicit controlled vocabulary (`CHECK` or `ENUM`).
2. `is_current` is explicitly non-authoritative.
3. `expected_version`, `event_sequence`, and `idempotency_key` remain distinct mechanisms.
4. Optimistic concurrency uses a conditional version check inside the controlled transition.
5. Approval records are append-only and cannot be rewritten by the approval writer.
6. Entity IDs are never physically deleted or reused.
7. Merge preserves the historical entity; split does not automatically migrate knowledge.
8. Evidence invalidation does not cascade into destructive knowledge mutation.
9. Actor/model/ruleset provenance is immutable after insertion.
10. Tenant overrides are separate from global scientific identity.
11. RAW records are immutable and cannot write Core.
12. `ON DELETE` behavior cannot cascade from tenant data into global scientific identity.

## 5. Review Sequence

Apply the controls in the approved dependency order:

`1 Core Write → 2 RLS + 3 FK/Delete → 4 Immutability → 5 Event Sequence → 6 Idempotency → 7 Required Fields + 8 Relationship Type → 9 Canonicalization → 10 Proposal/Approval → 11 Indexes`

Steps 2 and 3 may be reviewed in parallel. Steps 7 and 8 may be reviewed in parallel after structural prerequisites are stable.

## 6. Final Gate

The reviewer must record one of:

- **PASS — ALL CONTROLS**: all 11 controls and supporting hardening checks are enforceable and internally consistent.
- **FAIL — REVISION REQUIRED**: one or more controls remain ambiguous or bypassable.
- **BLOCKED — PREREQUISITE**: a required architectural decision is not yet approved.

Only **PASS — ALL CONTROLS** may advance to SQL migration design review.

**Production migration remains BLOCKED until separate schema review approval is recorded.**
