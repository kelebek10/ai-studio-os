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

Rules: `entity_id` is never physically deleted or reused; business keys are not identity keys; operational roles have no DELETE privilege; merge preserves the historical entity; split does not automatically migrate knowledge.

## 4. `core.entity_relationship`

```text
relationship_id   uuid PRIMARY KEY
from_entity_id    uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT
to_entity_id      uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT
relationship_type text NOT NULL CHECK (...)
created_at        timestamptz NOT NULL
created_by        uuid NOT NULL
```

`UNIQUE (from_entity_id, to_entity_id, relationship_type)` is mandatory.

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

`state` is authoritative. `is_current`, if present, is optimization only. Evidence invalidation never automatically destructively mutates knowledge.

## 6. `core.event_history`

```text
event_id          uuid PRIMARY KEY
entity_id         uuid NOT NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT
event_sequence    bigint NOT NULL CHECK (event_sequence > 0)
event_type        text NOT NULL CHECK (...)
aggregate_version bigint NOT NULL CHECK (aggregate_version > 0)
actor_id          uuid NOT NULL
actor_role        text NOT NULL
model_id          text NULL
model_version     text NULL
ruleset_version   text NULL
payload           jsonb NOT NULL
created_at        timestamptz NOT NULL
```

`UNIQUE (entity_id, event_sequence)` is mandatory. `event_sequence` is the ordered history number within the entity aggregate. Allocation must be transaction-safe; `MAX()+1` and timestamp ordering are prohibited.

## 7. `core.approval`

```text
approval_id       uuid PRIMARY KEY
proposal_id       uuid NULL REFERENCES research.proposal(proposal_id) ON DELETE RESTRICT
knowledge_id      uuid NOT NULL REFERENCES core.knowledge(knowledge_id) ON DELETE RESTRICT
actor_id          uuid NOT NULL
actor_role        text NOT NULL
workflow_type     text NOT NULL
expected_version  bigint NOT NULL CHECK (expected_version > 0)
event_sequence    bigint NOT NULL CHECK (event_sequence > 0)
idempotency_key   text NOT NULL
approval_type     text NOT NULL CHECK (...)
approved_at       timestamptz NOT NULL
```

Per approved C-03, the authoritative idempotency contract is:

`UNIQUE (idempotency_key)`.

A workflow may carry `workflow_type` for audit/semantics, but it does not weaken or replace the approved global uniqueness of `idempotency_key`.

Approval is append-only. `pai_approval_writer` receives INSERT only and cannot UPDATE/DELETE approval rows or write event history.

## 8. Evidence

### `evidence.record`

```text
evidence_id        uuid PRIMARY KEY
source_system      text NOT NULL
source_record_key  text NOT NULL
source_version     text NOT NULL
content_hash       text NOT NULL
captured_at        timestamptz NOT NULL
verification_state text NOT NULL CHECK (...)
status             text NOT NULL CHECK (...)
actor_id           uuid NOT NULL
created_at         timestamptz NOT NULL
```

Operational evidence writer: INSERT only. UPDATE/DELETE/TRUNCATE denied. Source revision creates a new record. Append-only protection is enforced by ownership/privilege separation, not application convention alone.

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
idempotency_key    text NOT NULL UNIQUE
```

RAW writer is INSERT only. UPDATE/DELETE/TRUNCATE denied. No RAW role has any Core write privilege.

## 10. `research.proposal`

```text
proposal_id          uuid PRIMARY KEY
proposal_fingerprint text NOT NULL UNIQUE
proposed_entity_id   uuid NULL REFERENCES core.entity(entity_id) ON DELETE RESTRICT
proposed_knowledge_id uuid NULL REFERENCES core.knowledge(knowledge_id) ON DELETE RESTRICT
model_id             text NOT NULL
model_version        text NOT NULL
ruleset_version      text NOT NULL
actor_id             uuid NOT NULL
status               text NOT NULL CHECK (...)
created_at            timestamptz NOT NULL
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

RLS requirements: `ENABLE ROW LEVEL SECURITY`; `FORCE ROW LEVEL SECURITY`; explicit SELECT/INSERT/UPDATE/DELETE policies; policies compare row `tenant_id` to a transaction-local authenticated tenant context; INSERT/UPDATE cannot choose another tenant; tenant application roles cannot set arbitrary tenant context; tenant roles cannot mutate `core.entity`; tenant override is separate from global identity.

RLS is combined with restrictive role privileges.

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

Controlled Core transition functions require fixed `search_path`, narrowly scoped `EXECUTE`, explicit `expected_version` checking, atomic state+event+approval transaction, and no client bypass. `SECURITY DEFINER` is used only where required and is owned by a dedicated non-login owner.

Target flow: `proposal/request → controlled service function → expected_version validation → Core state transition → event append → approval linkage → commit`.

## 13. Immutability / Provenance

Append-only after insertion: approval actor/role/workflow/version/idempotency; evidence source/version/hash/verification; RAW payload/hash/source; event actor/model/ruleset; proposal model/version/ruleset provenance.

Operational writers cannot UPDATE/DELETE these records. Dedicated non-login ownership prevents owner privilege leakage.

## 14. Concurrency Controls

The mechanisms are distinct:

- `expected_version`: optimistic concurrency expectation.
- `event_sequence`: ordered history identity within an aggregate.
- `idempotency_key`: duplicate-operation identity; globally unique per C-03.

A controlled state transition atomically verifies `stored_version = expected_version` and increments the authoritative version. Failed checks produce no partial Core mutation.

## 15. Referential Integrity / Deletion

Every FK explicitly declares `ON DELETE`. Baseline: global identity and historical references use `RESTRICT`. No cascade may delete scientific identity, evidence, approvals or history. Tenant deletion cannot cascade into global identity. Any future `CASCADE` requires a separate approved decision.

## 16. Canonicalization

Persist:

```text
canonicalization_ruleset_version text NOT NULL
canonical_key                    text NOT NULL
input_fingerprint                text NOT NULL
collision_state                  text NOT NULL CHECK (...)
```

Canonicalization is deterministic for identical normalized input + ruleset version. Collision state is reviewable and cannot trigger automatic entity merge. A new ruleset cannot silently redefine an existing scientific identity.

## 17. Proposal → Approval Integrity

Proposal fingerprint is unique. Approval references the originating proposal when applicable and the target Core knowledge/version. Approval is append-only. Proposal status cannot update Core. Core transition verifies `expected_version`. Model/version/actor provenance is immutable. Approval does not grant Core table privileges.

## 18. Index Baseline

Indexes must support real constraints/access paths: scientific identity/canonical lookup; relationship uniqueness/directional lookup; knowledge `(entity_id, knowledge_type, state)`; approval idempotency and expected-version lookup; event `(entity_id, event_sequence)`; evidence hash/source-version lookup; evidence↔knowledge bridge; proposal fingerprint; tenant FK/RLS predicates; RAW source identity/hash.

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

Before any SQL migration is authored: all 11 review controls PASS; supporting hardening checks PASS; schema review decision recorded with mandatory governance fields; Human Project Owner approval recorded.

**PRODUCTION MIGRATION = BLOCKED until then.**

## 21. Explicit Prohibitions

No production migration; no production DB mutation; no Google Sheets import into Core; no n8n Core write credentials; no AI direct Core mutation; no automatic canonicalization merge; no hard deletion of scientific identity/evidence/history; no premature Qdrant/RAG/KG/MCP/multi-agent implementation.
