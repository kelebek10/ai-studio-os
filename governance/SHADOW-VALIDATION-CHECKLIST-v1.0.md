# PAI-FORGE — SHADOW VALIDATION CHECKLIST

**Document:** SHADOW-VALIDATION-CHECKLIST-v1.0.md  
**Version:** 1.0  
**Status:** PROPOSED — CONTROLLED REVIEW REQUIRED  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`  
**Date:** 2026-09-12

## 1. Gate

Validation-only artifact. No production mutation is authorized.

## 2. Registry Integrity

- [ ] Registry primary keys unique.
- [ ] Registry codes unique.
- [ ] No code semantic collision.
- [ ] ACTIVE/DEPRECATED states valid.
- [ ] Seed set approved and versioned.

## 3. Knowledge Type Mapping

- [ ] Every legacy Knowledge Type value mapped deterministically or quarantined.
- [ ] No value maps to multiple registry identities.
- [ ] Historical DEPRECATED references remain resolvable.
- [ ] No silent normalization.
- [ ] Mapping ruleset version recorded.

## 4. Source Mapping

- [ ] Every legacy source value mapped deterministically or quarantined.
- [ ] No duplicate source identity.
- [ ] `source_version` preserved.
- [ ] `source_record_key` preserved.
- [ ] Content/payload hashes unchanged.
- [ ] Capture timestamps unchanged.

## 5. Zone / Scope Integrity

- [ ] Zone Type mapping does not alter `zone_id`.
- [ ] Zone lifecycle history unchanged.
- [ ] `record_zone` row count unchanged.
- [ ] GENEL records have zero zone relations.
- [ ] ZONA_OZEL cardinality remains exactly one.
- [ ] BOLGESEL cardinality remains one or more.
- [ ] Mixed relation kinds rejected.

## 6. Provenance / History

- [ ] Knowledge history preserved.
- [ ] Evidence↔Knowledge links preserved.
- [ ] RAW payloads and hashes unchanged.
- [ ] Approval history preserved.
- [ ] Event sequence preserved.
- [ ] Actor/model/ruleset provenance preserved.

## 7. Security

- [ ] n8n has no Core mutation privilege.
- [ ] AI/proposal roles cannot mutate Core.
- [ ] Registry cannot be mutated by tenant/application roles.
- [ ] RLS policies pass cross-tenant tests.
- [ ] Global scientific identity remains tenant-independent.

## 8. Performance / Scale

Execute the approved S1–S4 workload and record:
- p50/p95/p99 latency;
- EXPLAIN ANALYZE / BUFFERS;
- index usage;
- sequential scan changes;
- buffer hit ratio;
- index/table size;
- lock wait;
- transaction duration;
- connection count;
- CPU/RAM/WAL impact.

No latency threshold is invented here; acceptance thresholds must be fixed from the approved benchmark baseline before production approval.

## 9. Rollback Readiness

- [ ] Backup/restore checkpoint validated.
- [ ] Transitional columns preserved.
- [ ] FK enforcement can be safely reversed before cleanup.
- [ ] Registry seed rollback tested.
- [ ] No irreversible deletion exists in migration path.
- [ ] Stop conditions documented.

## 10. Final Result

Only one result is permitted:

**PASS — SHADOW VALIDATION COMPLETE**

or

**FAIL — REVISION REQUIRED**

Any FAIL keeps production migration BLOCKED.

Human Project Owner approval is required before production migration.
