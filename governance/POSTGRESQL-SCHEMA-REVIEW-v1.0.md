# PAI-FORGE — PostgreSQL Schema Review v1.0

**Document:** POSTGRESQL-SCHEMA-REVIEW-v1.0.md  
**Version:** 1.0  
**Status:** REQUIRES REVISION  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`  
**Reviewed Artifact:** `POSTGRESQL-SCHEMA-BLUEPRINT-v1.0.md`

## 1. Review Result

The blueprint is directionally correct and covers the architectural boundaries of C-01–C-34, but it is **not yet sufficiently enforceable at PostgreSQL level** to pass schema review.

No production migration is authorized.

## 2. Required Corrections

### R-01 — Relationship type enforcement
C-09 is described but no concrete CHECK/ENUM domain is defined. The schema blueprint must specify a controlled relationship-type domain and reject unknown values.

### R-02 — Event sequence scope
C-02 requires monotonic/history-safe sequencing. `(entity_id, event_sequence)` must be the authoritative uniqueness/order scope, with sequence allocation performed transactionally. A global unsafely shared sequence is not sufficient.

### R-03 — Idempotency scope
C-03 requires a concrete uniqueness boundary. Approval idempotency must be unique within the approval operation namespace, with explicit NULL/NOT NULL semantics.

### R-04 — Approval role boundary
`pai_approval_writer` must be restricted to approval INSERT operations and explicitly denied UPDATE/DELETE/TRUNCATE. It must not be described as a generic history writer.

### R-05 — Provenance immutability
C-22/C-23 require explicit immutable actor/model/version fields on proposal, approval and event records. “actor/model provenance” is currently too vague for schema enforcement.

### R-06 — Canonicalization storage
C-20/C-21 require an explicit persisted deterministic canonicalization result, ruleset version and input fingerprint, with a uniqueness/collision mechanism. A prose-only section is insufficient.

### R-07 — Tenant RLS enforcement
C-25/C-26/C-27 require concrete RLS policy boundaries, including tenant ownership checks and denial of tenant mutation against global `core.entity`/global knowledge. “RLS/policy boundaries” must be made explicit in the blueprint.

### R-08 — Deletion semantics
C-30 requires controlled `ON DELETE` behavior. Each FK class must specify RESTRICT/NO ACTION/CASCADE where applicable. Global identity and evidence relationships must default to preservation-safe behavior.

### R-09 — NOT NULL contract
C-31 requires the mandatory provenance/state fields to be explicitly identified rather than represented by generic prose.

### R-10 — State-transition authority
C-32 requires direct table mutation to be structurally restricted. The blueprint must state which Core tables are writable by `pai_core_service`, which operations are permitted, and that application roles cannot bypass the controlled transition path.

### R-11 — Historical preservation
C-33 requires explicit append-only treatment for history and approvals, plus preservation-safe FK behavior. The blueprint must distinguish logical status changes from physical deletion.

## 3. Gate Decision

**SCHEMA REVIEW: BLOCKED — REVISION REQUIRED**

The blueprint may not be converted into SQL migration until R-01 through R-11 are resolved and re-reviewed.

## 4. Next Action

Revise `POSTGRESQL-SCHEMA-BLUEPRINT-v1.0.md` with concrete PostgreSQL enforcement semantics, then perform Schema Review v1.1.

**Production migration remains BLOCKED.**
