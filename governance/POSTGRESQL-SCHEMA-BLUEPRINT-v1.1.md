# PAI-FORGE — PostgreSQL Schema Blueprint v1.1

**Document:** POSTGRESQL-SCHEMA-BLUEPRINT-v1.1.md  
**Version:** 1.1  
**Status:** REVISED FOR SCHEMA RE-REVIEW  
**Owner:** Human Project Owner  
**Scope:** P0 + P1 Identity/Core/Provenance controls  
**Branch:** `phase-1-3-foundation`

## 1. Purpose and Gate

This revision translates C-01–C-34 into enforceable PostgreSQL design requirements. It supersedes v1.0 for review purposes while preserving v1.0 as historical review material.

**This is a design artifact only. No production migration, data import, infrastructure mutation, or SQL execution is authorized.**

The blueprint cannot be marked APPROVED until the controlled review checklist records PASS — ALL CONTROLS.

## 2. Logical Schemas

- `core` — authoritative scientific identity, knowledge, relationships, approvals and controlled history.
- `evidence` — immutable evidence and provenance records plus evidence↔knowledge links.
- `research` — candidate/raw intake and AI/research proposals; never authoritative Core.
- `tenant` — tenant-scoped overrides and operational data.
- `audit` — append-only security/operational audit events.

Schema separation is a security boundary, not merely naming.

## 3. Controlled Vocabularies

Controlled values must be enforced with PostgreSQL `ENUM` or named `CHECK` constraints. Free-form application validation is insufficient.

Minimum controlled domains:

- `entity.status`
- `knowledge.state`
- `relationship_type`
- `approval` outcome/type where applicable
- `proposal.status`
- `evidence.status`
- tenant override status
- event type

The exact vocabulary values must be frozen during schema review before migration design. Adding a value is a versioned schema change; changing semantic meaning of an existing value is prohibited.

## 4. Core Entity

### `core.entity`

Purpose: permanent scientific identity.

Required fields:

- `entity_id uuid PRIMARY KEY`
- `entity_type ... NOT NULL`
- `scientific_identity_key ... NOT NULL UNIQUE`
- `canonical_name text NOT NULL`
- `created_at timestamptz NOT NULL`
- `created_by ... NOT NULL`
- `version bigint NOT NULL DEFAULT 1 CHECK (version > 0)`
- `status ... NOT NULL`

Rules:

- `entity_id` is permanent and never reused.
- No operational role has DELETE privilege.
- Physical deletion is prohibited by the Core security boundary.
- Business keys are separate from scientific identity.
- Merge is represented by governed relationship/event records; the historical entity survives.
- Split does not automatically migrate knowledge.

## 5. Core Relationships

### `core.entity_relationship`

Required fields:

- `relationship_id uuid PRIMARY KEY`
- `from_entity_id uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT`
- `to_entity_id uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT`
- `relationship_type ... NOT NULL`
- `created_at timestamptz NOT NULL`
- immutable actor/provenance fields NOT NULL where applicable

Constraint:

`UNIQUE(from_entity_id, to_entity_id, relationship_type)`.

Relationship types are DB-controlled. Invalid values are rejected at the database boundary.

## 6. Core Knowledge

### `core.knowledge`

Required fields:

- `knowledge_id uuid PRIMARY KEY`
- `entity_id uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT`
- `knowledge_type ... NOT NULL`
- `state ... NOT NULL`
- `payload jsonb NOT NULL`
- `ruleset_version text NOT NULL`
- `created_at timestamptz NOT NULL`
- `updated_at timestamptz NOT NULL`
- `version bigint NOT NULL DEFAULT 1 CHECK (version > 0)`

`state` is authoritative and DB-controlled. `is_current`, if retained for query optimization, is explicitly non-authoritative and cannot define truth independently of state/history.

Knowledge is never destructively invalidated merely because evidence becomes invalid.

## 7. Approval / State Transition

### `core.approval`

Append-only approval record.

Required fields:

- `approval_id uuid PRIMARY KEY`
- `proposal_id uuid NULL REFERENCES research.proposal(proposal_id) ON DELETE RESTRICT`
- `knowledge_id uuid NOT NULL REFERENCES core.knowledge(knowledge_id) ON DELETE RESTRICT`
- `actor_id ... NOT NULL`
- actor-role snapshot `... NOT NULL`
- `expected_version bigint NOT NULL`
- `event_sequence bigint NOT NULL`
- `idempotency_key text NOT NULL`
- approval outcome/type `... NOT NULL`
- `approved_at timestamptz NOT NULL`

Approval is append-only. The approval writer may INSERT approval records but cannot UPDATE/DELETE approval rows or write event history through that role.

Approval does not itself grant unrestricted table mutation. Core state transition occurs only through the controlled Core transition mechanism defined in Section 12.

## 8. Event History

### `core.event_history`

Required fields:

- `event_id uuid PRIMARY KEY`
- `entity_id uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT`
- `event_sequence bigint NOT NULL CHECK (event_sequence > 0)`
- `event_type ... NOT NULL`
- `aggregate_version bigint NOT NULL CHECK (aggregate_version > 0)`
- actor provenance `... NOT NULL`
- model provenance where applicable `... NULL`
- `ruleset_version text NULL`
- `payload jsonb NOT NULL`
- `created_at timestamptz NOT NULL`

`event_sequence` is scoped to the governed aggregate/history stream. The schema must enforce uniqueness at that scope, e.g. `UNIQUE(entity_id, event_sequence)` where entity is the aggregate boundary.

Allocation must be transaction-safe. Sequence allocation must not depend on application-generated timestamps or race-prone MAX()+1 logic.

`expected_version`, `event_sequence`, and `idempotency_key` are independent controls.

## 9. Evidence

### `evidence.record`

Required fields:

- `evidence_id uuid PRIMARY KEY`
- source identifier `... NOT NULL`
- source version `... NOT NULL`
- content hash `... NOT NULL`
- captured_at timestamptz NOT NULL
- verification metadata `... NOT NULL`
- status `... NOT NULL`
- actor/provenance `... NOT NULL`

Operational evidence writers are INSERT-only. UPDATE, DELETE and TRUNCATE are denied. New source revisions create new evidence records.

Append-only enforcement must not rely solely on application behavior; ownership/privilege separation and, where required, database trigger/function protections must prevent bypass by operational roles.

### `evidence.knowledge_link`

- `evidence_id uuid NOT NULL REFERENCES evidence.record(evidence_id) ON DELETE RESTRICT`
- `knowledge_id uuid NOT NULL REFERENCES core.knowledge(knowledge_id) ON DELETE RESTRICT`
- `link_type ... NOT NULL`
- `created_at timestamptz NOT NULL`

Primary key: `(evidence_id, knowledge_id)`.

Evidence invalidation never performs destructive knowledge mutation.

## 10. Research / RAW / Proposal

### `research.raw_record`

Required fields:

- `raw_id uuid PRIMARY KEY`
- `source_system text NOT NULL`
- `source_record_key text NOT NULL`
- `payload jsonb NOT NULL`
- `payload_hash text NOT NULL`
- `captured_at timestamptz NOT NULL`
- ingestion provenance `... NOT NULL`
- `idempotency_key text NOT NULL`

RAW is immutable. The RAW writer is INSERT-only. UPDATE/DELETE/TRUNCATE are denied. RAW has no privilege path to Core.

### `research.proposal`

Required fields:

- `proposal_id uuid PRIMARY KEY`
- `proposal_fingerprint text NOT NULL UNIQUE`
- proposed entity/knowledge references where applicable
- `model_id text NOT NULL`
- `model_version text NOT NULL`
- `ruleset_version text NOT NULL`
- actor/provenance `... NOT NULL`
- `status ... NOT NULL`
- `created_at timestamptz NOT NULL`

Proposal status is not Core state. A proposal cannot mutate Core through status changes. Approval requires an explicit controlled transition and traceable approval record.

## 11. Tenant Isolation / RLS

### `tenant.tenant`

- `tenant_id uuid PRIMARY KEY`
- metadata `... NOT NULL`
- status `... NOT NULL`

### `tenant.entity_override`

- `tenant_id uuid NOT NULL REFERENCES tenant.tenant(tenant_id) ON DELETE RESTRICT`
- `entity_id uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT`
- override payload `jsonb NOT NULL`
- version/history fields `... NOT NULL`

Primary key: `(tenant_id, entity_id)`.

Every tenant-scoped table has a non-null `tenant_id` and a tenant FK unless the table is itself the tenant registry.

RLS requirements:

1. `ENABLE ROW LEVEL SECURITY` on every tenant-scoped table.
2. `FORCE ROW LEVEL SECURITY` so table ownership does not silently bypass tenant policy for application paths.
3. Explicit SELECT/INSERT/UPDATE/DELETE policies using a transaction-local authenticated tenant context.
4. INSERT/UPDATE policies must require `tenant_id` to equal the authenticated tenant context.
5. Tenant application roles cannot set arbitrary tenant context through an untrusted client value.
6. Cross-tenant foreign-key combinations are prohibited by design.
7. Global `core.entity` has no tenant ownership column and cannot be mutated through tenant roles.
8. Tenant overrides are the only tenant-specific customization path unless separately approved.

RLS is a defense boundary, not the only authorization mechanism; role privileges remain restrictive.

## 12. Core Write Authority

Core mutation is a controlled workflow boundary.

Required security model:

- `pai_core_read`: SELECT only on approved Core views/tables.
- `pai_n8n`: no Core INSERT/UPDATE/DELETE/TRUNCATE privileges.
- AI/research roles: no authoritative Core mutation privileges.
- operational application roles: no unrestricted Core mutation privileges.
- `pai_core_service`: only role permitted to execute controlled Core transition functions/workflows.
- direct table mutation by application roles is denied even when a function exists.
- controlled functions use explicit transaction/concurrency checks and `SECURITY DEFINER` only where required, with fixed `search_path`, owner isolation, and narrowly scoped EXECUTE privileges.

The intended production pattern is:

`Proposal / approved request → controlled service function → expected_version check → state transition + event + approval linkage → commit`

No client may independently update `core.knowledge.state` and then claim approval.

## 13. Immutability / Provenance

The following are append-only after insertion:

- approval actor and actor-role snapshot
- evidence source/version/hash/capture metadata
- RAW payload/hash/source metadata
- event actor/model/ruleset provenance
- proposal model/version/ruleset provenance

Operational writer roles cannot UPDATE or DELETE these records.

Where ownership would otherwise permit bypass, tables must be owned by a dedicated non-login owner role and operational writers must not inherit owner or superuser-equivalent capabilities.

## 14. Concurrency and Idempotency

### Expected version — C-01/C-04

`expected_version` is the caller's optimistic concurrency expectation. A controlled transition succeeds only if the stored version equals the expected version; otherwise it fails without partial state mutation.

### Event sequence — C-02

`event_sequence` is the ordered history identifier inside the declared aggregate scope. Uniqueness is DB-enforced. Allocation is transaction-safe.

### Idempotency key — C-03

`idempotency_key` identifies a retryable operation in an explicit workflow scope. The uniqueness domain must include the operation scope, for example `(workflow_type, actor_id, idempotency_key)` where appropriate. A single global key column without a defined scope is insufficient.

These three mechanisms must never be substituted for one another.

## 15. Referential Integrity / ON DELETE

Every FK must specify explicit deletion semantics.

Baseline policy:

- global scientific identity references → `ON DELETE RESTRICT`
- historical evidence/event/approval references → `ON DELETE RESTRICT`
- tenant → tenant override → `ON DELETE RESTRICT`
- no tenant operation may cascade into `core.entity`
- no historical record may be deleted through a parent cascade

Any future CASCADE requires a separately approved schema decision proving that history and scientific identity are unaffected.

## 16. Required NOT NULL Contract

Mandatory identity, relationship, state, provenance, hash, version, timestamp and FK fields are explicitly `NOT NULL` in their table definitions. Nullable fields are permitted only where absence has a defined semantic meaning.

A migration review must reject any table definition that relies on “required fields” prose without an actual `NOT NULL`, `CHECK`, FK, UNIQUE or equivalent DB constraint.

## 17. Canonicalization

Canonicalization persists:

- `canonicalization_ruleset_version text NOT NULL`
- deterministic `canonical_key text NOT NULL`
- normalized-input `input_fingerprint text NOT NULL`
- review/collision state `... NOT NULL`

The deterministic identity candidate is derived from normalized input + ruleset version. Repeating the same input under the same ruleset yields the same candidate key.

A collision is a reviewable condition. It cannot automatically merge entities.

Canonicalization must not redefine an existing scientific identity merely because a later ruleset produces a different candidate.

## 18. Proposal → Approval Integrity

The proposal layer remains non-authoritative.

Required integrity:

- `research.proposal.proposal_id` is the traceable origin of an approval where a proposal exists.
- proposal fingerprint is unique.
- approval records are append-only.
- approval references the target Core knowledge/version.
- controlled transition verifies `expected_version`.
- proposal status cannot directly update Core.
- AI model/version and actor provenance remain immutable.
- no approval row alone grants a client direct Core table privileges.

## 19. Index Baseline

Indexes must support actual constraints and expected access paths.

Required baseline:

- entity scientific identity and canonical lookup
- relationship uniqueness and directional lookup
- knowledge `(entity_id, knowledge_type, state)`
- approval idempotency scope and `(knowledge_id, expected_version)` where query patterns justify it
- event `(entity_id, event_sequence)`
- evidence content hash and source/version lookup
- evidence↔knowledge bridge keys
- proposal fingerprint
- tenant FKs and RLS predicates
- RAW source identity and payload hash

No speculative index is mandatory. Final index selection is part of schema review, not production tuning after the fact.

## 20. Role Boundary Summary

| Role | Core read | Core mutation | Approval | Evidence | RAW | Research | Tenant |
|---|---|---|---|---|---|---|---|
| `pai_owner` | controlled | administrative/governed | governed | governed | governed | governed | governed |
| `pai_core_service` | yes | controlled functions only | controlled transition | no direct write | no | no | no |
| `pai_core_read` | yes | no | read as permitted | read as permitted | no | no | no |
| `pai_approval_writer` | limited | no | INSERT only | no | no | no | no |
| `pai_evidence_writer` | limited | no | no | INSERT only | no | no | no |
| `pai_raw_writer` | no Core | no | no | no | INSERT only | no | no |
| `pai_research_writer` | no authoritative Core | no | no | no | no | proposal/raw candidate writes | no |
| `pai_tenant_app` | approved tenant views/data | tenant-scoped only via RLS | no | no | no | no | yes |
| `pai_n8n` | transport-only as required | **DENIED** | no | no | intake only | candidate intake only | no |

## 21. Constraint Coverage

| Matrix | v1.1 enforcement |
|---|---|
| C-01–C-04 | explicit version, event sequence, idempotency and controlled transition semantics |
| C-05–C-08 | append-only approval, permanent entity, governed merge/split |
| C-09–C-10 | DB-controlled relationship type + unique relationship |
| C-11–C-15 | M:N evidence links + explicit knowledge state + non-authoritative `is_current` |
| C-16–C-18 | Core role isolation + proposal separation + unique fingerprint |
| C-19–C-21 | business/identity separation + deterministic canonicalization + collision review |
| C-22–C-23 | immutable actor/model/ruleset provenance |
| C-24–C-27 | global scientific identity + tenant RLS + separate overrides |
| C-28–C-29 | immutable RAW + no RAW→Core write path |
| C-30–C-31 | explicit FK delete actions + concrete NOT NULL contract |
| C-32–C-33 | controlled transition + historical preservation |
| C-34 | separate tenant/scientific namespaces |

## 22. Review Gates

Before SQL migration design:

1. Core write authority PASS.
2. Tenant RLS PASS.
3. FK/ON DELETE PASS.
4. Immutability/provenance PASS.
5. Event sequence PASS.
6. Idempotency PASS.
7. Required fields PASS.
8. Relationship type PASS.
9. Canonicalization PASS.
10. Proposal→Approval PASS.
11. Index/query hardening PASS.
12. Supporting hardening checks PASS.
13. Human Project Owner approval recorded.

Until every gate passes, production migration remains BLOCKED.

## 23. Explicitly Blocked

- Production migration.
- SQL execution against production.
- Current Google Sheets import into Core.
- n8n Core write credentials.
- AI direct Core mutation.
- Automatic merge on canonicalization collision.
- Hard deletion of scientific entities, evidence, approvals or history.
- Premature Qdrant/RAG/KG/MCP/multi-agent implementation.

## 24. Next Step

Run `POSTGRESQL-SCHEMA-REVIEW-CHECKLIST-v1.0.md` line-by-line against this v1.1 blueprint and record the result in a versioned Schema Review decision artifact.
