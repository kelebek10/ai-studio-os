# PEYZAJ AI / PAI-FORGE — ZONE DICTIONARY SCHEMA

**Document:** ZONE-DICTIONARY-SCHEMA-v1.0.md  
**Version:** 1.0  
**Status:** APPROVED  
**Date:** 2026-09-12  
**Owner:** Human Project Owner / Baş Mimar  

## Decision

Zone Dictionary PostgreSQL çekirdek şeması v1.0 APPROVED olarak tanımlanmıştır. Bu belge migration değildir. Üretim veritabanında herhangi bir değişiklik bu belgeye dayanılarak otomatik uygulanamaz; migration ayrıca hazırlanacak, gözden geçirilecek ve ayrıca onaylanacaktır.

## Core model

```text
zone
  -> immutable scientific/geographic identity
zone_current_state
  -> authoritative current state, controlled through approval procedures
zone_approval_event
  -> immutable decision/history log
zone_relationship
  -> immutable merge/split/alias lifecycle relationships
zone_microclimate_profile
  -> versioned current/historical microclimate profiles
zone_fallback_rule
  -> human-approved fallback governance object
record_zone
  -> normalized Knowledge Record <-> Zone M:N relation
```

## Approved invariants

1. `zone_id` is authoritative and immutable.
2. `zone_code` is a stable human-readable business key; it is not identity.
3. `candidate_ref` is provenance/reference only; it is not identity.
4. Zone hierarchy uses `parent_zone_id`; geographic hierarchy is not encoded in `zone_id`.
5. `display_path` is derived/read-only and never authoritative for decisions.
6. PostgreSQL is authoritative for Zone Dictionary; Sheets is only a candidate/research interface.
7. Microclimate is separate from zone boundary.
8. One zone has at most one active microclimate profile; historical profiles are preserved.
9. Microclimate replacement is performed only through an approval procedure; historical business values are not silently overwritten.
10. `zone_relationship` is the authoritative lifecycle relationship log. `merged_into_zone_id`, if retained as materialized state, is non-authoritative and derived from relationship history.
11. Approval events are append-only.
12. Approval targets use typed nullable foreign keys, not polymorphic `(target_type,target_id)` references.
13. `event_sequence` is a global ordering key; gaps are allowed, uniqueness is mandatory, continuity is not required.
14. `expected_version`, `event_sequence`, and `idempotency_key` are distinct controls with distinct purposes.
15. Optimistic concurrency requires `expected_version = current_state.version`; successful approval increments `version` exactly once.
16. `idempotency_key` is unique and prevents duplicate approval submissions.
17. Human approval is mandatory for authoritative Zone state transitions; AI cannot directly approve or mutate authoritative Zone state.
18. `record_zone` is normalized M:N. `ZONA_OZEL` produces exactly one relation, `BOLGESEL` produces one or more relations, and `GENEL` produces no `record_zone` row.
19. `knowledge_record.kapsam` remains authoritative for scope semantics; `record_zone.relation_kind` represents the normalized relationship.
20. Cross-table scope/cardinality consistency is enforced transactionally, not by a simple row-level CHECK.
21. `source_zone_id = target_zone_id` is forbidden for fallback rules.
22. Absence of an approved fallback rule means NO-DATA; fallback is never inferred by string parsing.
23. n8n/Candidate Selection has SELECT-only access and cannot write authoritative Zone state.
24. Approval workflow writes through controlled database procedures/functions; direct UPDATE privilege on `zone_current_state` is not granted to the approval role.
25. Production migration is blocked until migration SQL, security/privilege review, trigger/procedure review, and human approval are complete.

## K-06 — event ordering

```sql
CREATE SEQUENCE zone_approval_event_sequence_seq
    AS BIGINT
    INCREMENT BY 1
    START WITH 1
    CACHE 1;

ALTER TABLE zone_approval_event
    ALTER COLUMN event_sequence SET DEFAULT nextval('zone_approval_event_sequence_seq');

ALTER TABLE zone_approval_event
    ALTER COLUMN event_sequence SET NOT NULL;

ALTER TABLE zone_approval_event
    ADD CONSTRAINT uq_zone_approval_event_sequence
    UNIQUE (event_sequence);
```

`event_sequence` is a global ordering key. Sequence gaps caused by rollback or sequence allocation are valid and must not be treated as errors.

## K-07 — optimistic concurrency

`zone_current_state.version` is authoritative for current-state concurrency.

```sql
ALTER TABLE zone_current_state
    ALTER COLUMN version SET DEFAULT 1;

ALTER TABLE zone_current_state
    ADD CONSTRAINT ck_zone_current_state_version_positive
    CHECK (version >= 1);
```

Every approval procedure that changes current state MUST:

```text
1. lock/read the current state;
2. compare p_expected_version with current version;
3. reject stale requests;
4. create the immutable approval event;
5. update current state;
6. increment version exactly once;
7. commit all operations in one transaction.
```

A stale request MUST NOT overwrite current state.

## K-08 — microclimate versioning

```sql
CREATE UNIQUE INDEX zone_microclimate_active_uq
    ON zone_microclimate_profile (zone_id)
    WHERE superseded_at IS NULL;
```

Profile replacement semantics:

```text
current profile
    -> controlled UPDATE: superseded_at = now()
    -> INSERT new profile
    -> same approval transaction
```

The `superseded_at` UPDATE is permitted only inside the controlled approval procedure. It is not a general application write path. Historical profile rows are never deleted.

## Approval event target integrity

`zone_approval_event` MUST use typed nullable foreign keys:

```text
ZONE                  -> target_zone_id
MICROCLIMATE_PROFILE  -> target_profile_id
RELATIONSHIP          -> target_relationship_id
FALLBACK_RULE         -> target_fallback_rule_id
```

Exactly one target FK is populated according to `target_type`. All target FKs are real PostgreSQL foreign keys and may use `DEFERRABLE INITIALLY DEFERRED` where required to resolve the Zone creation transaction.

## Circular creation workflow

For Zone creation, the Zone row and its approval event may reference each other through deferred constraints and MUST be created in one transaction. The transaction must not become two independent writes.

## State / event separation

```text
IMMUTABLE HISTORY:
  zone_approval_event
  zone_relationship

CURRENT AUTHORITATIVE STATE:
  zone_current_state

IMMUTABLE IDENTITY:
  zone.zone_id
```

`zone_current_state` is writable only through controlled approval procedures. Its state must always be backed by an approval event.

## Record-zone normalization

Sheets candidate representation may use:

```text
kapsam_detay = "14;18;23"
```

PostgreSQL MUST normalize this into:

```text
record_zone(record_id, zone_id, relation_kind)
```

GENEL records have no `record_zone` rows.

`UNIQUE(record_id, zone_id)` prevents duplicate membership.

The exact cross-table cardinality validation between `knowledge_record.kapsam` and `record_zone` is a deferred transactional constraint and will be finalized when `knowledge_record` is designed.

## Security boundary

```text
n8n/app_role
  -> SELECT only on Zone Dictionary read/candidate-selection objects
  -> no authoritative write

approval_role
  -> INSERT approval/history objects as required
  -> EXECUTE approved state-transition procedures
  -> no direct UPDATE on zone_current_state

Human Project Owner
  -> final authority for approval decisions
```

AI proposals are never equivalent to approval and cannot directly mutate authoritative Zone state.

## Migration gate

Status is APPROVED for schema architecture only.

The following remain blocked until separately reviewed and approved:

- production migration
- physical PostgreSQL schema deployment
- creation of 25–35 production zones
- automated Sheets → Core write path
- unrestricted application write credentials

## Next step

Design `knowledge_record` schema, then complete the real `record_zone` foreign key and cross-table cardinality constraint. After that, perform a final migration/security review before writing migration SQL.
