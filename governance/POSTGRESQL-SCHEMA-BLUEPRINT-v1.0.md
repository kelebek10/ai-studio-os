# PAI-FORGE — PostgreSQL Schema Blueprint v1.0

**Document:** POSTGRESQL-SCHEMA-BLUEPRINT-v1.0.md  
**Version:** 1.0  
**Status:** PROPOSED FOR SCHEMA REVIEW  
**Owner:** Human Project Owner  
**Scope:** P0 + P1 Identity/Core/Provenance controls  
**Branch:** `phase-1-3-foundation`

## 1. Purpose

This blueprint translates the approved Identity Model v1.2 Constraint Matrix (C-01–C-34) into a reviewable PostgreSQL design. It is a design artifact only.

**No production migration, data import, or infrastructure mutation is authorized by this document.**

## 2. Logical Schemas

- `core` — authoritative scientific identity, knowledge, relationships, approvals, and controlled history.
- `evidence` — immutable evidence/provenance records and evidence↔knowledge links.
- `research` — candidate/raw intake and AI/research proposals; never authoritative Core.
- `tenant` — tenant-scoped overrides and tenant-owned operational data.
- `audit` — append-only operational/security audit events where required.

Schema separation is a security boundary, not only a naming convention.

## 3. Core Tables

### `core.entity`

Purpose: permanent scientific identity.

Key fields:
- `entity_id uuid PRIMARY KEY`
- `entity_type`
- `scientific_identity_key`
- `canonical_name`
- `created_at`
- `created_by`
- `version bigint NOT NULL DEFAULT 1`
- `status`

Rules:
- No physical DELETE privilege.
- `entity_id` is never reused.
- Business keys are indexed separately and are never identity keys.

### `core.entity_relationship`

- `relationship_id uuid PRIMARY KEY`
- `from_entity_id uuid NOT NULL REFERENCES core.entity(entity_id)`
- `to_entity_id uuid NOT NULL REFERENCES core.entity(entity_id)`
- `relationship_type`
- provenance fields
- timestamps

Constraint:
`UNIQUE(from_entity_id, to_entity_id, relationship_type)`.

Merge/split operations are represented through governed relationships/events; they do not delete the historical entity.

### `core.knowledge`

- `knowledge_id uuid PRIMARY KEY`
- `entity_id uuid NOT NULL REFERENCES core.entity(entity_id)`
- `knowledge_type`
- `state`
- `payload jsonb`
- `ruleset_version`
- `created_at`
- `updated_at`
- `version bigint NOT NULL DEFAULT 1`

Knowledge state is authoritative; `is_current` is not.

### `core.approval`

Append-only approval record.

- `approval_id uuid PRIMARY KEY`
- `proposal_id uuid`
- `knowledge_id uuid`
- `actor_id`
- actor-role snapshot
- `expected_version`
- `event_sequence`
- `idempotency_key`
- `approved_at`

Database role for approvals is INSERT-only. UPDATE/DELETE are denied.

### `core.event_history`

Append-only state/history stream.

- `event_id uuid PRIMARY KEY`
- `entity_id`
- `event_sequence bigint NOT NULL`
- `event_type`
- `aggregate_version`
- actor/model provenance
- `payload jsonb`
- `created_at`

`event_sequence` is independent of `expected_version` and `idempotency_key`.

## 4. Evidence Tables

### `evidence.record`

Immutable source/evidence record.

- `evidence_id uuid PRIMARY KEY`
- source/provenance metadata
- content hash
- source version
- captured_at
- verification metadata
- `status`

No DELETE privilege. Source revision creates a new record/version rather than mutating history.

### `evidence.knowledge_link`

M:N bridge.

- `evidence_id REFERENCES evidence.record`
- `knowledge_id REFERENCES core.knowledge`
- link role/type
- created_at

Primary key: `(evidence_id, knowledge_id)`.

Evidence invalidation does not cascade into destructive knowledge mutation.

## 5. Research / Proposal Tables

### `research.raw_record`

Immutable intake payload.

- `raw_id uuid PRIMARY KEY`
- `source_system`
- `source_record_key`
- `payload jsonb NOT NULL`
- `payload_hash`
- `captured_at`
- ingestion metadata
- `idempotency_key`

Writer role: INSERT only. UPDATE/DELETE/TRUNCATE denied.

### `research.proposal`

AI/research candidate state, never Core.

- `proposal_id uuid PRIMARY KEY`
- `proposal_fingerprint UNIQUE NOT NULL`
- proposed entity/knowledge references
- `model_id`
- `model_version`
- `ruleset_version`
- `actor/provenance`
- `status`
- `created_at`

Proposal approval is a separate controlled transition into Core.

## 6. Tenant Tables

### `tenant.tenant`

- `tenant_id uuid PRIMARY KEY`
- tenant metadata
- status

### `tenant.entity_override`

- `tenant_id REFERENCES tenant.tenant`
- `entity_id REFERENCES core.entity`
- override payload
- version/history fields

Primary key: `(tenant_id, entity_id)`.

Tenant overrides never mutate global scientific identity.

All tenant-scoped tables require `tenant_id` and are protected by PostgreSQL RLS/policy boundaries.

## 7. Canonicalization

Canonicalization produces a deterministic key from normalized input plus `ruleset_version`.

Required fields:
- `canonicalization_ruleset_version`
- deterministic canonical key
- input fingerprint

A collision is surfaced as a reviewable condition. It never triggers automatic entity merge.

## 8. Permissions / Roles

Minimum role model:

- `pai_owner` — human-controlled administrative authority.
- `pai_core_service` — controlled Core state transitions only.
- `pai_core_read` — read-only Core access.
- `pai_approval_writer` — INSERT-only approval/history operations.
- `pai_evidence_writer` — INSERT-only evidence operations.
- `pai_raw_writer` — INSERT-only RAW operations.
- `pai_research_writer` — research/proposal writes only.
- `pai_tenant_app` — tenant-scoped application access through RLS.
- `pai_n8n` — transport/intake role; explicitly denied Core write privileges.

Application users do not receive direct unrestricted Core mutation privileges.

## 9. Concurrency / Idempotency

Three independent mechanisms are mandatory:

1. `expected_version` — optimistic concurrency check.
2. `event_sequence` — ordered historical event identity.
3. `idempotency_key` — duplicate request prevention.

State transitions must use conditional updates or stored/service-layer transactions that verify the expected version.

## 10. Referential Integrity / Deletion Policy

- Scientific entities: no hard delete.
- Evidence: no hard delete.
- Historical events/approvals: append-only.
- Relationship FKs: controlled `ON DELETE` behavior; default policy is RESTRICT where historical integrity requires preservation.
- Tenant records: deletion semantics must not cascade into global scientific identity.

## 11. Index Baseline

Required initial indexes include:

- entity scientific/canonical lookup keys.
- entity relationship uniqueness and directional lookup.
- knowledge `(entity_id, knowledge_type, state)`.
- approval `idempotency_key` and `(knowledge_id, expected_version)`.
- event history `(entity_id, event_sequence)`.
- evidence content hash and source/version identifiers.
- evidence↔knowledge bridge keys.
- proposal fingerprint.
- tenant-scoped foreign keys and RLS access paths.
- RAW payload hash and source record identity.

Indexes will be refined during schema review against expected query patterns; speculative indexes are not mandatory.

## 12. Constraint Coverage

| Matrix | Blueprint control |
|---|---|
| C-01–C-04 | approval/event/version/idempotency model |
| C-05–C-08 | append-only approval/entity + governed merge/split |
| C-09–C-10 | controlled relationship type + unique relationship |
| C-11–C-15 | evidence↔knowledge M:N + explicit knowledge state |
| C-16–C-18 | research proposal separation + unique fingerprint |
| C-19–C-21 | separate business identity + deterministic canonicalization |
| C-22–C-23 | immutable actor/model provenance |
| C-24–C-27 | global identity + tenant isolation/override |
| C-28–C-29 | immutable RAW + schema/role isolation |
| C-30–C-31 | FK + NOT NULL + controlled deletion |
| C-32–C-33 | controlled state transition + historical preservation |
| C-34 | separate tenant/scientific namespaces |

## 13. Review Gates

Before implementation:

1. Table and relationship review.
2. Constraint review against C-01–C-34.
3. Role/permission review.
4. RLS/tenant isolation review.
5. Append-only/immutability review.
6. Transaction/concurrency review.
7. Query/index review.
8. Migration/reversibility plan review.
9. Human Project Owner approval.

Only after these gates may a versioned PostgreSQL migration be authored.

## 14. Explicitly Blocked

- Production migration.
- Production database mutation.
- Importing the current Google Sheets dataset into Core.
- Giving n8n Core write credentials.
- AI direct Core mutation.
- Automatic merge on canonicalization collision.
- Hard deletion of scientific entities/evidence/history.
- Premature Qdrant/RAG/KG/MCP/multi-agent implementation.

## 15. Next Step

**Schema Review v1.0**: validate this blueprint line-by-line against C-01–C-34, security boundaries, tenant isolation, transaction semantics, and expected access patterns. Resolve review findings before any SQL migration is created.
