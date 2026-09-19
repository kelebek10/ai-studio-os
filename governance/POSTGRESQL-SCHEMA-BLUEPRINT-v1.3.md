# PAI-FORGE — PostgreSQL Schema Blueprint v1.3

**Document:** POSTGRESQL-SCHEMA-BLUEPRINT-v1.3.md  
**Version:** 1.3  
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

Additional v1.3 controlled domains:

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

`constraint` represents stable identity. `constraint_version` represents an immutable revision.

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

Constraint versions are append-only. `SAFETY_ENGINEERING + NON_NEGOTIABLE` requires validated evidence. Classification→enforcement→priority is deterministic and cannot be changed by LLM/runtime input.

## 5. Design State Boundary

Minimum persistence boundary only; full application contract remains separate.

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

A Design State version is immutable. The database boundary must prevent UPDATE/DELETE of historical versions for operational roles. New state means a new row/version. No alternate table may serve as a mutable substitute.

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

Records are immutable analysis facts. `source_id` is not treated as a polymorphic FK; controlled service validation must verify source existence and type before acceptance.

## 7. Feasibility Evaluation

```text
feasibility_evaluation_id uuid PRIMARY KEY
design_state_id           uuid NOT NULL REFERENCES design_state(design_state_id) ON DELETE RESTRICT
input_hash                text NOT NULL
result                    text NOT NULL CHECK (...)
engine_id                 text NOT NULL
engine_version            text NOT NULL
ruleset_version           text NOT NULL
created_at                timestamptz NOT NULL
```

Every evaluation must identify its exact input through `input_hash`. The input canonicalization must include the action/change request identity, Design State version/hash, applicable constraint versions and relevant impact/dependency context. `PARTIALLY_FEASIBLE` cannot authorize automatic application.

## 8. Conflict

```text
conflict_id          uuid PRIMARY KEY
action_id            uuid NOT NULL
change_request_id    uuid NULL
design_state_id      uuid NOT NULL REFERENCES design_state(design_state_id) ON DELETE RESTRICT
state_version        bigint NOT NULL
state_hash           text NOT NULL
status               text NOT NULL CHECK (...)
created_at           timestamptz NOT NULL
created_by            uuid NOT NULL
```

A conflict binds to the exact Design State snapshot and originating action/request. Relevant constraint versions are linked through an immutable bridge:

```text
conflict_constraint
conflict_id           uuid NOT NULL REFERENCES conflict(conflict_id) ON DELETE RESTRICT
constraint_version_id uuid NOT NULL REFERENCES constraint_version(constraint_version_id) ON DELETE RESTRICT
PRIMARY KEY (conflict_id, constraint_version_id)
```

The stored state version/hash must match the referenced Design State. Safety-vs-safety conflicts require Engineering Review and cannot be auto-resolved.

## 9. Alternative

```text
alternative_id       uuid PRIMARY KEY
conflict_id          uuid NOT NULL REFERENCES conflict(conflict_id) ON DELETE RESTRICT
status               text NOT NULL CHECK (...)
proposal_hash        text NOT NULL
feasibility_id       uuid NULL REFERENCES feasibility_evaluation(feasibility_evaluation_id) ON DELETE RESTRICT
created_at           timestamptz NOT NULL
created_by            uuid NOT NULL
```

An Alternative is distinct from evaluation and application. Its feasibility evaluation must use the same exact Design State and applicable constraint-version snapshot identified by the alternative input hash.

## 10. Resolution

```text
resolution_id        uuid PRIMARY KEY
conflict_id          uuid NOT NULL REFERENCES conflict(conflict_id) ON DELETE RESTRICT
alternative_id       uuid NULL REFERENCES alternative(alternative_id) ON DELETE RESTRICT
status               text NOT NULL CHECK (...)
decision_hash        text NOT NULL
actor_id             uuid NOT NULL
created_at            timestamptz NOT NULL
```

Resolution is append-only. Operational roles cannot UPDATE/DELETE it. A later decision creates a new resolution row; historical resolutions remain reconstructible.

## 11. Approval Event Ledger

Approval history is an append-only ledger distinct from mutable workflow state.

```text
approval_event_id    uuid PRIMARY KEY
resolution_id        uuid NOT NULL REFERENCES resolution(resolution_id) ON DELETE RESTRICT
event_type           text NOT NULL CHECK (...)
actor_id             uuid NOT NULL
actor_role           text NOT NULL
authorization_ref    text NOT NULL
idempotency_key      text NOT NULL UNIQUE
created_at            timestamptz NOT NULL
```

Approval-event writers receive INSERT only. UPDATE/DELETE/TRUNCATE are denied. Authorization must be checked against the approved principal/role; an AI model cannot self-authorize.

## 12. Candidate / Verified / Approved Boundary

Candidate, Verified and Approved records remain distinguishable. Status alone is insufficient to authorize Core mutation. Controlled transition functions must validate the required lifecycle transition and provenance. No proposal, resolution candidate, constraint version or AI-generated record may become Core-authoritative through direct table mutation.

## 13. Change Request Boundary / Replay

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

`request_key` identifies the canonical request identity. The canonical representation must include request identity, Design State version/hash, constraint versions and deterministic ruleset version. Exact replay must resolve to the existing request/evaluation rather than create a second application. A request is stale when authoritative state version differs from `expected_state_version`; stale requests cannot mutate Core.

## 14. Cross-Model Provenance

Constraint, impact/dependency, feasibility, conflict, alternative, resolution and approval-event records retain immutable actor/ruleset/engine provenance appropriate to their role. Critical predecessor references must be explicit. Deterministic evaluation identifies engine/ruleset version. LLM output may be stored as proposal/context but cannot override deterministic controls.

## 15. Referential Integrity / Immutability

All v1.3 foreign keys use explicit deletion policy; baseline is `ON DELETE RESTRICT`. Historical/scientific records are never hard-deleted. Operational writers cannot UPDATE/DELETE versioned audit records. Core identity references remain immutable and are never reused. No cascade may invalidate an audit chain.

## 16. Concurrency / Integrity Enforcement

The controlled transition boundary must atomically validate:

1. expected Design State version;
2. exact state hash where required;
3. constraint-version snapshot;
4. canonical request/idempotency identity;
5. candidate→verified→approved transition;
6. required approval authorization;
7. resulting Core version before mutation.

Failure causes rollback with no partial Core mutation. Physical locking/version checks are implementation details of the controlled transition function and transaction.

## 17. Index Baseline

Indexes must support: constraint key/version lookup; design `(design_id, state_version)` and hash; conflict action/request/state lookup; conflict-constraint bridge; feasibility input hash and design state; change request request_key/hash; approval-event idempotency; and tenant predicates where applicable.

No speculative index is required.

## 18. Control Coverage

The v1.1 C-01–C-34 controls remain active. v1.3 additionally requires demonstrable enforcement of:

- immutable constraint versions and safety evidence;
- deterministic classification/enforcement/priority mapping;
- immutable Design State version/hash;
- exact action/request + conflict-state binding;
- impact/dependency traceability;
- feasibility input binding and provenance;
- Alternative/evaluation separation;
- immutable Resolution;
- append-only authorized Approval Event ledger;
- candidate/verified/approved transition boundary;
- stale-state blocking;
- deterministic replay/idempotency protection;
- immutable Core identity references;
- no alternate Design State mutation path;
- Safety-vs-Safety → Engineering Review;
- PARTIALLY_FEASIBLE → no automatic apply.

## 19. Migration Gate

Before any SQL migration is authored: existing schema review controls PASS; all v1.3 controls PASS; supporting hardening checks PASS; governance decision is recorded; Human Project Owner approval is recorded.

**PRODUCTION MIGRATION = BLOCKED until then.**

## 20. Explicit Prohibitions

No production migration; no production DB mutation; no Google Sheets import into Core; no n8n Core write credentials; no AI direct Core mutation; no automatic canonicalization merge; no hard deletion of scientific identity/evidence/history; no premature Qdrant/RAG/KG/MCP/multi-agent implementation; no full Design State or Change Request application contract in this revision.
