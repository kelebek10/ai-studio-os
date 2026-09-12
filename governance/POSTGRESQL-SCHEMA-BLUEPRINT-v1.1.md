# PAI-FORGE — PostgreSQL Schema Blueprint v1.1

**Document:** POSTGRESQL-SCHEMA-BLUEPRINT-v1.1.md  
**Version:** 1.1  
**Status:** REVISED FOR SCHEMA RE-REVIEW  
**Owner:** Human Project Owner  
**Scope:** P0 + P1 Identity/Core/Provenance controls  
**Branch:** `phase-1-3-foundation`

## 1. Gate

This is a design artifact only. No production migration, SQL execution, data import, or infrastructure mutation is authorized.

The blueprint is not APPROVED until the controlled schema review records **PASS — ALL CONTROLS**.

## 2. PostgreSQL Domains / Controlled Values

Use PostgreSQL `ENUM` or named `CHECK` constraints for all controlled states. Minimum controlled domains:

- `entity_type text CHECK (...)`
- `entity.status text CHECK (...)`
- `knowledge_type text CHECK (...)`
- `knowledge.state text CHECK (...)`
- `relationship_type text CHECK (...)`
- `approval_type text CHECK (...)`
- `proposal.status text CHECK (...)`
- `evidence.status text CHECK (...)`
- `event_type text CHECK (...)`
- `tenant.status text CHECK (...)`
- `tenant_override.status text CHECK (...)`

The exact allowed values must be frozen in the migration review. Application-only validation is not authoritative.

## 3. `core.entity`

Permanent scientific identity.

```text
entity_id               uuid PRIMARY KEY
entity_type             text NOT NULL
scientific_identity_key text NOT NULL UNIQUE
canonical_name          text NOT NULL
created_at              timestamptz NOT NULL
created_by              uuid NOT NULL
version                 bigint NOT NULL DEFAULT 1 CHECK (version > 0)
status                  text NOT NULL CHECK (...)
```

Rules:

- `entity_id` is never physically deleted or reused.
- Business keys are not identity keys.
- Operational roles have no DELETE privilege.
- Merge preserves the historical entity.
- Split does not automatically migrate knowledge.

## 4. `core.entity_relationship`

```text
relationship_id   uuid PRIMARY KEY
from_entity_id    uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT
to_entity_id      uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT
relationship_type text NOT NULL CHECK (...)
created_at        timestamptz NOT NULL
created_by        uuid NOT NULL
```

Required constraint:

`UNIQUE (from_entity_id, to_entity_id, relationship_type)`.

## 5. `core.knowledge`

```text
knowledge_id    uuid PRIMARY KEY
entity_id       uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT
knowledge_type  text NOT NULL CHECK (...)
state           text NOT NULL CHECK (...)
payload         jsonb NOT NULL
ruleset_version text NOT NULL
created_at      timestamptz NOT NULL
updated_at      timestamptz NOT NULL
version         bigint NOT NULL DEFAULT 1 CHECK (version > 0)
```

`state` is authoritative. `is_current`, if present, is an optimization only and never defines truth. Evidence invalidation never automatically destructively mutates knowledge.

## 6. `core.event_history`

```text
event_id         uuid PRIMARY KEY
entity_id        uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT
event_sequence   bigint NOT NULL CHECK (event_sequence > 0)
event_type       text NOT NULL CHECK (...)
aggregate_version bigint NOT NULL CHECK (aggregate_version > 0)
actor_id         uuid NOT NULL
actor_role       text NOT NULL
model_id         text NULL
model_version    text NULL
ruleset_version  text NULL
payload          jsonb NOT NULL
created_at       timestamptz NOT NULL
```

Required:

`UNIQUE (entity_id, event_sequence)`.

`event_sequence` is the ordered history number within the entity aggregate. Allocation must be transaction-safe; `MAX()+1` and timestamp ordering are prohibited.

## 7. `core.approval`

```text
approval_id       uuid PRIMARY KEY
proposal_id       uuid NULL REFERENCES research.proposal(proposal_id) ON DELETE RESTRICT
knowledge_id      uuid NOT NULL REFERENCES core.knowledge(knowledge_id) ON DELETE RESTRICT
actor_id          uuid NOT NULL
actor_role        text NOT NULL
workflow_type     text NOT NULL
expected_version  bigint NOT NULL CHECK (expected_version > 0)
event_sequence   bigint NOT NULL CHECK (event_sequence > 0)
idempotency_key   text NOT NULL
approval_type     text NOT NULL CHECK (...)
approved_at       timestamptz NOT NULL
```

Required idempotency constraint:

`UNIQUE (workflow_type, actor_id, idempotency_key)`.

If a future workflow requires a different scope, it must define a separate approved uniqueness domain rather than silently reusing this one.

Approval is append-only. `pai_approval_writer` receives INSERT only and cannot UPDATE/DELETE approval rows or write event history.

## 8. Evidence

### `evidence.record`

```text
evidence_id       uuid PRIMARY KEY
source_system     text NOT NULL
source_record_key text NOT NULL
source_version    text NOT NULL
content_hash      text NOT NULL
captured_at       timestamptz NOT NULL
verification_state text NOT NULL CHECK (...)
status            text NOT NULL CHECK (...)
actor_id          uuid NOT NULL
created_at        timestamptz NOT NULL
```

Operational evidence writer: INSERT only. UPDATE/DELETE/TRUNCATE denied.

Source revision creates a new record. Append-only protection must be enforced by ownership/privilege separation; application convention alone is insufficient.

### `evidence.knowledge_link`

```text
evidence_id uuid NOT NULL REFERENCES evidence.record(evidence_id) ON DELETE RESTRICT
knowledge_id uuid NOT NULL REFERENCES core.knowledge(knowledge_id) ON DELETE RESTRICT
link_type text NOT NULL CHECK (...)
created_at timestamptz NOT NULL
PRIMARY KEY (evidence_id, knowledge_id)
```

## 9. `research.raw_record`

```text
raw_id             uuid PRIMARY KEY
source_system      text NOT NULL
source_record_key  text NOT NULL
payload            jsonb NOT NULL
payload_hash       text NOT NULL
captured_at        timestamptz NOT NULL
actor_id           uuid NOT NULL
idempotency_key    text NOT NULL
```

RAW writer is INSERT only. UPDATE/DELETE/TRUNCATE denied. No RAW role has any Core write privilege.

## 10. `research.proposal`

```text
proposal_id        uuid PRIMARY KEY
proposal_fingerprint text NOT NULL UNIQUE
proposed_entity_id uuid NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT
proposed_knowledge_id uuid NULL REFERENCES core.knowledge(knowledge_id) ON DELETE RESTRICT
model_id           text NOT NULL
model_version      text NOT NULL
ruleset_version    text NOT NULL
actor_id           uuid NOT NULL
status             text NOT NULL CHECK (...)
created_at         timestamptz NOT NULL
```

Proposal status is never Core state. Proposal rows cannot directly mutate Core.

## 11. Tenant / RLS

### `tenant.tenant`

```text
tenant_id  uuid PRIMARY KEY
name       text NOT NULL
status     text NOT NULL CHECK (...)
created_at timestamptz NOT NULL
```

### `tenant.entity_override`

```text
tenant_id uuid NOT NULL REFERENCES tenant.tenant(tenant_id) ON DELETE RESTRICT
entity_id uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT
payload   jsonb NOT NULL
version   bigint NOT NULL CHECK (version > 0)
status    text NOT NULL CHECK (...)
created_at timestamptz NOT NULL
updated_at timestamptz NOT NULL
PRIMARY KEY (tenant_id, entity_id)
```

Every tenant-scoped table has `tenant_id NOT NULL` and tenant FK unless it is the tenant registry.

RLS requirements:

1. `ENABLE ROW LEVEL SECURITY`.
2. `FORCE ROW LEVEL SECURITY`.
3. Explicit SELECT/INSERT/UPDATE/DELETE policies.
4. Policies compare row `tenant_id` to a transaction-local authenticated tenant context.
5. INSERT/UPDATE cannot choose another tenant.
6. Tenant application roles cannot set arbitrary tenant context.
7. Tenant roles cannot mutate `core.entity`.
8. Tenant override is separate from global scientific identity.

RLS is combined with restrictive role privileges; it is not the sole security boundary.

## 12. Core Write Authority

Roles:

- `pai_owner`: human-controlled administrative authority.
- `pai_core_service`: only role allowed to execute controlled Core transition functions.
- `pai_core_read`: read-only Core access.
- `pai_approval_writer`: approval INSERT only.
- `pai_evidence_writer`: evidence INSERT only.
- `pai_raw_writer`: RAW INSERT only.
- `pai_research_writer`: research/proposal writes; no Core mutation.
- `pai_tenant_app`: tenant-scoped access through RLS.
- `pai_n8n`: transport/intake only; no Core mutation.

Operational roles receive no direct Core INSERT/UPDATE/DELETE/TRUNCATE privilege.

Controlled Core transition function requirements:

- fixed `search_path`;
- narrowly scoped `EXECUTE` grants;
- explicit `expected_version` check;
- atomic state + event + approval linkage transaction;
- no client-controlled bypass;
- `SECURITY DEFINER` only where required, owned by a dedicated non-login owner.

Target flow:

`proposal/request → controlled service function → expected_version validation → Core state transition → event append → approval linkage → commit`.

## 13. Immutability / Provenance

Append-only after insertion:

- approval actor, role, workflow, expected version, idempotency key;
- evidence source/version/hash/verification metadata;
- RAW payload/hash/source metadata;
- event actor/model/ruleset provenance;
- proposal model/version/ruleset provenance.

Operational writers cannot UPDATE/DELETE these records. Dedicated non-login ownership prevents owner privilege leakage into application roles.

## 14. Concurrency Controls

The mechanisms are distinct:

- `expected_version`: optimistic concurrency expectation.
- `event_sequence`: ordered history identity within an aggregate.
- `idempotency_key`: retry/duplicate-operation identity within a declared workflow scope.

A controlled state transition must atomically verify `stored_version = expected_version` and increment the authoritative version. Failed concurrency checks produce no partial Core mutation.

## 15. Referential Integrity / Deletion

Every FK explicitly declares `ON DELETE`.

Baseline: historical/global identity references use `RESTRICT`. No cascade may delete scientific identity, evidence, approvals or history. Tenant deletion cannot cascade into global identity.

Any future `CASCADE` requires a separate approved decision.

## 16. Canonicalization

Persist:

```text
canonicalization_ruleset_version text NOT NULL
canonical_key                    text NOT NULL
input_fingerprint                text NOT NULL
collision_state                  text NOT NULL CHECK (...)
```

Canonicalization is deterministic for identical normalized input + ruleset version.

Collision state is reviewable and cannot trigger automatic entity merge. A new ruleset cannot silently redefine an existing scientific identity.

## 17. Proposal → Approval Integrity

- Proposal fingerprint is unique.
- Approval references the originating proposal when applicable.
- Approval references the target Core knowledge/version.
- Approval is append-only.
- Proposal status cannot update Core.
- Core transition verifies `expected_version`.
- Model/version/actor provenance is immutable.
- Approval does not grant Core table privileges.

## 18. Index Baseline

Indexes must support real constraints/access paths:

- scientific identity and canonical lookup;
- relationship uniqueness/directional lookup;
- knowledge `(entity_id, knowledge_type, state)`;
- approval idempotency scope and expected-version lookup;
- event `(entity_id, event_sequence)`;
- evidence hash/source-version lookup;
- evidence↔knowledge bridge;
- proposal fingerprint;
- tenant FK/RLS predicates;
- RAW source identity/hash.

No speculative index is required.

## 19. C-01–C-34 Coverage

| Controls | Enforcement |
|---|---|
| C-01–C-04 | distinct version/event/idempotency mechanisms + controlled transition |
| C-05–C-08 | append-only approval + permanent entity + governed merge/split |
| C-09–C-10 | DB-controlled relationship type + unique relationship |
| C-11–C-15 | M:N evidence links + explicit knowledge state + non-authoritative `is_current` |
| C-16–C-18 | role separation + proposal separation + fingerprint uniqueness |
| C-19–C-21 | identity/business separation + deterministic canonicalization + collision review |
| C-22–C-23 | immutable actor/model/ruleset provenance |
| C-24–C-27 | global identity + tenant RLS + separate overrides |
| C-28–C-29 | immutable RAW + no RAW→Core path |
| C-30–C-31 | explicit FK deletion + concrete NOT NULL contract |
| C-32–C-33 | controlled state transition + history preservation |
| C-34 | separate tenant/scientific namespaces |

## 20. Migration Gate

Before any SQL migration is authored:

1. All 11 review controls PASS.
2. Supporting hardening checks PASS.
3. Schema review decision is recorded with mandatory governance fields.
4. Human Project Owner approves the reviewed schema.

Until then:

**PRODUCTION MIGRATION = BLOCKED.**

## 21. Explicit Prohibitions

- No production migration.
- No production DB mutation.
- No Google Sheets import into Core.
- No n8n Core write credentials.
- No AI direct Core mutation.
- No automatic canonicalization merge.
- No hard deletion of scientific identity/evidence/history.
- No premature Qdrant/RAG/KG/MCP/multi-agent implementation.
