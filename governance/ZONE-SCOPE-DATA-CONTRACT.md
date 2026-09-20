# PEYZAJ AI / PAI-FORGE — ZONE SCOPE DATA CONTRACT

**Document:** ZONE-SCOPE-DATA-CONTRACT.md  
**Version:** 1.2  
**Status:** PROPOSED — NOT YET APPROVED  
**Classification:** GOVERNANCE / DATA CONTRACT  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`  
**Last Updated:** 2026-09-12

## 1. Purpose

This contract defines how Knowledge records express geographic scope and how candidate Google Sheets data is normalized into the authoritative Core model.

It is intentionally PROPOSED until `knowledge_record` and `record_zone` are finalized and pass integrated schema review.

## 2. Required Fields

- `botanical_name` — required.
- `kayit_seviyesi` — required: `TUR_DUZEYI | CESIT_DUZEYI`.
- `cultivar_code` — required only for `CESIT_DUZEYI`; NULL for `TUR_DUZEYI`.
- `kapsam` — required: `ZONA_OZEL | BOLGESEL | GENEL`.
- `kapsam_detay` — required only for `BOLGESEL` in the Sheets candidate representation.

## 3. Scope Semantics

### 3.1 ZONA_OZEL

Requires:

- `zone_id`
- `zone_code`

Both must resolve to the same authoritative Zone Dictionary row.

### 3.2 BOLGESEL

- Candidate Sheets representation may contain `kapsam_detay` as a semicolon-separated list of Zone Dictionary IDs, for example `14;18;23`.
- The list is candidate/input representation only.
- PostgreSQL/Core MUST NOT persist this list as a TEXT field.
- It must be normalized to `record_zone(record_id, zone_id, relation_kind)` with `relation_kind = BOLGESEL_UYE`.

### 3.3 GENEL

- `zone_id` and `zone_code` are NULL.
- No `record_zone` relationship row is created.
- `kapsam_detay` is NULL.

## 4. Authoritative Semantics

`knowledge_record.kapsam` is authoritative for scope semantics.

`record_zone.relation_kind` is a normalized relationship attribute and must not become an independent source of truth for scope.

Mandatory cross-table invariants:

```text
GENEL       -> 0 record_zone rows
ZONA_OZEL   -> exactly 1 record_zone row, relation_kind=ZONA_OZEL
BOLGESEL    -> >=1 record_zone rows, relation_kind=BOLGESEL_UYE
NO MIX      -> one record cannot mix ZONA_OZEL and BOLGESEL_UYE
```

These rules require transaction-level/deferred enforcement after `knowledge_record` is finalized; a row-level CHECK alone is insufficient.

## 5. Validation and Quarantine

Invalid or unresolved candidate records are routed to `QUARANTINE` / `belirsiz_kayitlar`.

Examples include:

- missing mandatory fields,
- invalid enum values,
- cultivar code present at species level,
- missing required zone data for `ZONA_OZEL`,
- unresolved zone IDs,
- malformed regional scope lists.

Invalid candidate data must never be silently corrected into authoritative Core data.

## 6. n8n Boundary

n8n Code Nodes may:

- validate schema,
- normalize technical formatting,
- filter,
- sort,
- select candidates,
- identify NO-DATA,
- route invalid records to quarantine.

n8n MUST NOT:

- write authoritative Core state,
- approve scientific data,
- perform scientific verification,
- merge/split entities or zones,
- infer missing scientific information,
- create or alter authoritative hierarchy.

## 7. Fallback Rule

Scientific fallback is governed separately by approved Zone fallback rules.

No string parsing, geographic guessing or AI inference may silently establish a fallback.

If no approved fallback applies, the result is `NO-DATA` and requires explicit handling.

## 8. Controlled Flow

```text
Veritabani_Temiz
    -> Schema Validation
    -> QUARANTINE / belirsiz
    -> Candidate Selection
    -> Shadow Test
    -> Human Review
    -> Production Approval
```

This contract does not authorize production migration or direct Sheets-to-Core writes.

## 9. Dependencies / Approval Gate

Before this contract can become APPROVED:

1. `knowledge_record` must be finalized.
2. `record_zone.record_id` must have a real FK to the authoritative Knowledge record.
3. Scope/cardinality constraints must be transactionally enforceable.
4. Existing PostgreSQL Blueprint v1.1 must be reconciled with this contract.
5. Integrated schema review must PASS all mandatory controls.

**Decision:** PROPOSED — do not treat this document as an approved production contract until all gates above pass.
