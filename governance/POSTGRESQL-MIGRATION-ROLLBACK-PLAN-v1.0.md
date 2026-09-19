# PAI-FORGE — POSTGRESQL MIGRATION ROLLBACK PLAN

**Version:** 1.0  
**Status:** PROPOSED — CONTROLLED REVIEW REQUIRED  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`

## Purpose
Define a reversible migration strategy before any production migration. This document does not authorize production execution.

## Rollback principles
- No destructive operation before validation gates pass.
- Legacy compatibility fields remain available through the validation window.
- Registry seed data is versioned and auditable.
- Backfill is idempotent and restartable.
- Original RAW payloads, hashes and provenance are never reconstructed from transformed data.
- Any unresolved or ambiguous mapping is quarantined.

## Rollback levels

### R0 — Mapping rollback
Stop the backfill and discard only staged target mappings. No authoritative data is changed.

### R1 — Constraint rollback
If FK validation/enforcement fails, disable only the newly introduced enforcement path through the approved migration procedure while preserving legacy compatibility fields. Do not delete registry records.

### R2 — Application authority rollback
If application reads/writes fail after registry authority activation, return authoritative access to the validated pre-migration representation using the preserved compatibility fields. Freeze further migration until root cause is resolved.

### R3 — Restore checkpoint
If data integrity cannot be guaranteed, restore from the validated pre-migration backup/checkpoint. Restore must be tested before production approval.

## Stop conditions
Immediate rollback/freeze on:
- unexpected row loss;
- hash/provenance mismatch;
- non-deterministic mapping;
- duplicate registry identity;
- FK orphan;
- scope/cardinality change;
- RLS boundary violation;
- unacceptable query regression;
- failed backup/restore verification.

## Recovery validation
After rollback:
1. Compare row counts.
2. Compare content hashes where applicable.
3. Verify provenance reconstruction.
4. Verify `record_zone` cardinality.
5. Verify evidence↔knowledge links.
6. Verify tenant isolation and role permissions.
7. Record incident, cause, affected batch and recovery result.

## Production rule
A rollback plan is not considered PASS until the restore checkpoint and at least one controlled rollback scenario have been successfully exercised in a non-production environment.

**Production migration remains BLOCKED.**
