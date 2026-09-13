# PAI-FORGE — PostgreSQL Schema Blueprint v1.2

**Document:** POSTGRESQL-SCHEMA-BLUEPRINT-v1.2.md  
**Version:** 1.2  
**Status:** REVISED FOR CONTROLLED SCHEMA RE-REVIEW  
**Owner:** Human Project Owner  
**Scope:** P0 + P1 Identity/Core/Provenance + Constraint/Conflict enforcement boundaries  
**Branch:** `phase-1-3-foundation`

## 1. Gate

Design artifact only. No production migration, SQL execution, data import, or infrastructure mutation is authorized.

The blueprint is not APPROVED until the controlled schema review records **PASS — ALL CONTROLS**.

## 2. Existing Foundation

The v1.1 identity, evidence, RAW, proposal, tenant/RLS, Core write authority, immutability, provenance, concurrency, referential-integrity, canonicalization and proposal→approval controls remain normative unless explicitly superseded below.

## 3. Controlled Values

All controlled states use PostgreSQL ENUMs or named CHECK constraints. Application-only validation is not authoritative.

Additional v1.2 controlled domains:

- `constraint.classification`
- `constraint.enforcement`
- `constraint.priority`
- `feasibility.result`
- `conflict.status`
- `alternative.status`
- `resolution.status`
- `change_request.status`
- `approval_event.type`

## 4. Constraint / Constraint Version

`constraint` represents the stable constraint identity. `constraint_version` represents an immutable revision.

```text
constraint_id       uuid PRIMARY KEY
constraint_key      text NOT NULL UNIQUE
classification      text NOT NULL CHECK (...)
created_at          timestamptz NOT NULL
created_by          uuid NOT NULL

constraint_version_id uuid PRIMARY KEY
constraint_id         uuid NOT NULL REFERENCES constraint(constraint_id) ON DELETE RESTRICT
version               bigint NOT NULL CHECK (version > 0)
enforcement           text NOT NULL CHECK (...)
priority              text NOT NULL CHECK (...)
ruleset_version       text NOT NULL
content_hash          text NOT NULL
provenance_ref        uuid NULL REFERENCES evidence.record(evidence_id) ON DELETE RESTRICT
created_at            timestamptz NOT NULL
created_by            uuid NOT NULL
UNIQUE (constraint_id, version)
```

Constraint versions are append-only. Safety/scientific-engineering + NON_NEGOTIABLE constraints require evidence provenance. Classification→enforcement→priority is controlled, deterministic, and cannot be reinterpreted by an LLM.

## 5. Design State Boundary

Only the minimum persistence boundary is introduced here; the full application contract remains separate.

```text
design_state_id       uuid PRIMARY KEY
design_id             uuid NOT NULL
state_version         bigint NOT NULL CHECK (state_version > 0)
state_hash            text NOT NULL
ruleset_version       text NOT NULL
created_at             timestamptz NOT NULL
created_by             uuid NOT NULL
UNIQUE (design_id, state_version)
UNIQUE (design_id, state_hash)
```

A Design State version is immutable. Existing versions cannot be updated in place. Any new state creates a new version. No alternate table/path may mutate an existing Design State version.

## 6. Impact / Dependency Record

```text
impact_dependency_id uuid PRIMARY KEY
design_state_id      uuid NOT NULL REFERENCES design_state(design_state_id) ON DELETE RESTRICT
source_type          text NOT NULL CHECK (...)
source_id            uuid NOT NULL
impact_type          text NOT NULL CHECK (...)
dependency_type      text NOT NULL CHECK (...)
result               text NOT NULL CHECK (...)
ruleset_version      text NOT NULL
provenance_ref       uuid NULL REFERENCES evidence.record(evidence_id) ON DELETE RESTRICT
created_at            timestamptz NOT NULL
```

Records are immutable analysis facts. `source_id` is interpreted only with the controlled `source_type`; no free-form polymorphic foreign key is treated as a referential-integrity guarantee.

## 7. Feasibility Evaluation

```text
feasibility_evaluation_id uuid PRIMARY KEY
design_state_id           uuid NOT NULL REFERENCES design_state(design_state_id) ON DELETE RESTRICT
result                    text NOT NULL CHECK (...)
engine_id                 text NOT NULL
engine_version            text NOT NULL
ruleset_version           text NOT NULL
input_hash                text NOT NULL
output_hash               text NOT NULL
created_at                timestamptz NOT NULL
```

Allowed result values include `FEASIBLE`, `INFEASIBLE`, `PARTIALLY_FEASIBLE`, `REQUIRES_REVIEW`. `PARTIALLY_FEASIBLE` cannot authorize automatic application. Evaluation provenance is immutable.

## 8. Conflict

```text
conflict_id          uuid PRIMARY KEY
design_state_id      uuid NOT NULL REFERENCES design_state(design_state_id) ON DELETE RESTRICT
state_version        bigint NOT NULL
state_hash           text NOT NULL
status               text NOT NULL CHECK (...)
created_at           timestamptz NOT NULL
created_by           uuid NOT NULL
```

A conflict must bind to the exact Design State snapshot. Relevant constraint versions are linked through an immutable bridge:

```text
conflict_constraint
conflict_id          uuid NOT NULL REFERENCES conflict(conflict_id) ON DELETE RESTRICT
constraint_version_id uuid NOT NULL REFERENCES constraint_version(constraint_version_id) ON DELETE RESTRICT
PRIMARY KEY (conflict_id, constraint_version_id)
```

The stored state version/hash must match the referenced Design State. Safety-vs-safety conflicts cannot be auto-resolved and require Engineering Review.

## 9. Alternative

```text
alternative_id       uuid PRIMARY KEY
conflict_id          uuid NOT NULL REFERENCES conflict(conflict_id) ON DELETE RESTRICT
status               text NOT NULL CHECK (...)
proposal_hash        text NOT NULL
feasibility_id       uuid NULL REFERENCES feasibility_evaluation(feasibility_evaluation_id) ON DELETE RESTRICT
created_at           timestamptz NOT NULL
created_by           uuid NOT NULL
```

An Alternative is distinct from a feasibility evaluation. Alternatives are auditable and cannot silently alter the conflict or Design State.

## 10. Resolution

```text
resolution_id        uuid PRIMARY KEY
conflict_id          uuid NOT NULL REFERENCES conflict(conflict_id) ON DELETE RESTRICT
alternative_id       uuid NULL REFERENCES alternative(alternative_id) ON DELETE RESTRICT
status               text NOT NULL CHECK (...)
decision_hash        text NOT NULL
actor_id             uuid NOT NULL
created_at           timestamptz NOT NULL
```

Resolution is append-only/immutable. It cannot rewrite the originating conflict, constraints or Design State.

## 11. Approval Event Ledger

Approval history for constraint/conflict resolution is represented as append-only events, distinct from mutable workflow state.

```text
approval_event_id    uuid PRIMARY KEY
resolution_id        uuid NOT NULL REFERENCES resolution(resolution_id) ON DELETE RESTRICT
event_type           text NOT NULL CHECK (...)
actor_id             uuid NOT NULL
actor_role           text NOT NULL
authorization_ref    text NOT NULL
idempotency_key      text NOT NULL UNIQUE
created_at           timestamptz NOT NULL
```

No UPDATE/DELETE is permitted to operational approval-event writers. Authorization is explicit; an AI model cannot self-authorize an approval transition.

## 12. Candidate / Verified / Approved Boundary

Candidate, Verified and Approved records remain distinguishable. A proposal, constraint version, evidence item or resolution candidate cannot become Core-authoritative merely by application status convention. Controlled transition functions are the only Core write boundary.

## 13. Change Request Boundary

Only the persistence boundary is introduced in v1.2; the full Change Request application contract is deferred.

```text
change_request_id      uuid PRIMARY KEY
request_key            text NOT NULL UNIQUE
design_state_id        uuid NOT NULL REFERENCES design_state(design_state_id) ON DELETE RESTRICT
expected_state_version bigint NOT NULL CHECK (expected_state_version > 0)
canonical_request_hash text NOT NULL
status                 text NOT NULL CHECK (...)
created_at             timestamptz NOT NULL
created_by             uuid NOT NULL
```

A request is stale when the authoritative Design State version differs from `expected_state_version`. Stale requests cannot mutate Core. Canonical request identity must be deterministic so replay does not create duplicate application.

## 14. Cross-Model Provenance

Constraint, impact/dependency, feasibility, conflict, alternative, resolution and approval-event records must retain immutable actor/ruleset/engine provenance appropriate to their role. Deterministic evaluation must identify the engine/ruleset version. LLM output may be stored as proposal/context but cannot override deterministic feasibility, priority, blocking or approval controls.

## 15. Referential Integrity / Immutability

All v1.2 foreign keys use explicit deletion policy; baseline is `ON DELETE RESTRICT`. Historical and scientific records are never hard-deleted. Versioned records are append-only. No cascade may invalidate an audit chain.

Physical implementation of optimistic concurrency remains a schema/transaction concern; the contract invariant is that stale state cannot be applied.

## 16. Index Baseline

In addition to v1.1 access paths, indexes must support: constraint key/version lookup; design `(design_id, state_version)`; state hash; conflict state/version; conflict-constraint bridge; feasibility by design state and result; change request request_key/hash; approval-event idempotency; and tenant predicates where applicable.

No speculative index is required.

## 17. Control Coverage

The v1.1 C-01–C-34 controls remain active. New v1.2 controls must additionally demonstrate:

- constraint version immutability;
- deterministic classification/enforcement/priority mapping;
- evidence requirement for safety/non-negotiable constraints;
- immutable Design State snapshot/version/hash;
- exact conflict-state binding;
- impact/dependency traceability;
- deterministic feasibility provenance;
- Alternative vs evaluation separation;
- immutable Resolution;
- append-only Approval Event ledger;
- candidate/verified/approved separation;
- stale Change Request blocking;
- deterministic replay/idempotency protection;
- immutable Core identity references;
- no alternate Design State mutation path;
- Safety-vs-Safety → Engineering Review;
- PARTIALLY_FEASIBLE → no automatic apply.

## 18. Migration Gate

Before any SQL migration is authored: existing schema review controls PASS; all v1.2 controls above PASS; supporting hardening checks PASS; governance decision is recorded; Human Project Owner approval is recorded.

**PRODUCTION MIGRATION = BLOCKED until then.**

## 19. Explicit Prohibitions

No production migration; no production DB mutation; no Google Sheets import into Core; no n8n Core write credentials; no AI direct Core mutation; no automatic canonicalization merge; no hard deletion of scientific identity/evidence/history; no premature Qdrant/RAG/KG/MCP/multi-agent implementation; no full Design State or Change Request application contract in this revision.
