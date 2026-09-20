# PAI-FORGE — SHADOW VALIDATION TEST PLAN

**Version:** 1.0  
**Status:** PROPOSED — CONTROLLED TEST PLAN  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`

## Objective
Validate registry migration mappings and structural invariants without mutating production authoritative state.

## Test sequence

### SV-01 — Inventory parity
Compare source and target row counts by controlled entity/type.
**PASS:** expected counts reconcile; any intentional exclusions are documented.

### SV-02 — Deterministic Knowledge Type mapping
Map every legacy `knowledge_type` using the versioned mapping ruleset.
**PASS:** every value resolves to exactly one registry identity or explicit QUARANTINE.

### SV-03 — Deterministic Source mapping
Map every legacy `source_system` to `registry.source`.
**PASS:** exactly one identity or explicit QUARANTINE; no silent creation.

### SV-04 — Zone Type reconciliation
Validate zone type vocabulary against the Zone Dictionary.
**PASS:** zone identity/lifecycle is unchanged; no `zone_id` replacement.

### SV-05 — Scope/cardinality preservation
Compare `GENEL`, `ZONA_OZEL`, `BOLGESEL` semantics and `record_zone` relationships.
**PASS:** no unauthorized scope or cardinality change.

### SV-06 — Provenance integrity
Compare source version, source record key, content hash, timestamps and RAW payload references.
**PASS:** no provenance loss or hash mismatch.

### SV-07 — Evidence linkage integrity
Compare evidence↔knowledge M:N links.
**PASS:** link counts and identities reconcile.

### SV-08 — Idempotency
Run the same mapping/backfill operation twice in shadow mode.
**PASS:** second execution creates no duplicate authoritative identity or duplicate mapping.

### SV-09 — Quarantine behavior
Inject unknown and ambiguous controlled values into a non-production fixture.
**PASS:** records enter QUARANTINE; no AI inference or automatic registry creation occurs.

### SV-10 — RLS / role boundary
Attempt reads/writes using application, n8n, evidence, RAW and tenant roles.
**PASS:** only explicitly authorized controlled functions can mutate authoritative registry/Core state.

### SV-11 — Rollback rehearsal
Execute R0/R1/R2 on a disposable validation dataset.
**PASS:** system returns to the pre-migration logical state and validation checks pass.

### SV-12 — Scale regression
Execute representative S1–S4 queries and index checks.
**PASS:** no unacceptable latency, sequential-scan or lock regression against agreed thresholds.

## Evidence required
For every test:
- test ID;
- dataset/version;
- mapping ruleset version;
- before/after counts;
- checksum/hash where applicable;
- quarantine count;
- result PASS/FAIL;
- failure details;
- reviewer/approval record.

## Gate
All mandatory tests must PASS before final schema approval. A failed test keeps production migration BLOCKED.

**No production SQL execution is authorized by this document.**
