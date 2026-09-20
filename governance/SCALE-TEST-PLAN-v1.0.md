# PAI-FORGE — SCALE TEST PLAN

**Document:** SCALE-TEST-PLAN-v1.0.md  
**Version:** 1.0  
**Status:** PROPOSED — CONTROLLED REVIEW REQUIRED  
**Owner:** Human Project Owner  
**Branch:** `phase-1-3-foundation`  
**Date:** 2026-09-12

## 1. Purpose

Validate whether the current PAI-FORGE data model remains operationally viable as Knowledge, Evidence and Knowledge↔Zone relationships grow from 1,000 to 1,000,000 records.

This is a benchmark design, not a production-load claim. No production migration or infrastructure mutation is authorized by this document.

## 2. Scale tiers

| Tier | Knowledge | Entity | Evidence target | record_zone target |
|---|---:|---:|---:|---:|
| S1 | 1,000 | 1,000 | 3,000–10,000 | 1,000–5,000 |
| S2 | 10,000 | 10,000 | 30,000–100,000 | 10,000–50,000 |
| S3 | 100,000 | 100,000 | 300,000–1,000,000 | 100,000–500,000 |
| S4 | 1,000,000 | 1,000,000 | 3,000,000–10,000,000 | 1,000,000–5,000,000 |

Evidence and record_zone ratios are test parameters, not production assumptions.

## 3. Query workload

Each tier must test at minimum:

- entity → knowledge lookup
- scientific identity lookup
- knowledge_type + state filtering
- scope + zone filtering
- zone → records
- record → zones
- knowledge → evidence
- evidence → knowledge
- source + source_version + hash lookup
- JSONB key/numeric/nested filtering
- JSONB + relational filtering
- current-state retrieval
- zone + knowledge_type + state composite query
- proposal → knowledge lookup
- tenant-scoped lookup/RLS path
- pagination and ordered retrieval

Use `EXPLAIN (ANALYZE, BUFFERS)` for representative queries.

## 4. Index tests

Validate:

- expected Index Scan/Bitmap usage
- absence of unexpected sequential scans
- selectivity of composite indexes
- heap fetch cost
- buffer hit behavior
- partial-index candidates at S3/S4
- index size and bloat
- planner stability as cardinality increases

Do not add speculative indexes before benchmark evidence.

## 5. JSONB tests

Test simple key lookup, numeric filtering, nested fields, arrays, relational + JSONB predicates, GIN indexing and large/variable payloads.

Deterministic filtering, joins, authorization, scope enforcement and scientific decision fields must remain typed relational data. JSONB is reserved for extensible attributes that do not require authoritative relational constraints.

## 6. Evidence tests

At each tier test:

- Knowledge → Evidence retrieval
- Evidence → Knowledge retrieval
- source/source_version filtering
- content_hash lookup and duplicate detection
- verification/status filtering
- M:N bridge joins
- invalidated/superseded evidence retrieval

The benchmark must include both low-density and high-density evidence attachment patterns.

## 7. record_zone tests

Test average zone memberships of 1, 3, 10 and 25 per Knowledge record.

At S4 this produces up to approximately 25M bridge rows and must be treated as a dedicated stress scenario.

Validate:

- record → zones
- zone → records
- zone + relation_kind filtering
- duplicate rejection
- scope cardinality enforcement
- no mixed relation kinds
- GENEL = zero bridge rows
- ZONA_OZEL = exactly one row
- BOLGESEL = one or more rows

## 8. Extensibility tests

### Zone types
Adding a new controlled Zone type must not require rewriting existing Knowledge records.

### Knowledge types
Adding a new Knowledge type must not require destructive migration of existing Knowledge records.

### Sources
Adding a new source system must not require a schema migration merely to register the source.

### Attributes
Adding non-critical extensible attributes must be possible without turning deterministic Core fields into opaque JSONB.

## 9. Performance metrics

Capture at minimum:

- p50 latency
- p95 latency
- p99 latency
- rows examined
- execution plan
- buffer hits/misses
- sequential scan count
- index size
- table size
- WAL volume
- CPU
- RAM
- active connections
- lock waits
- transaction duration

## 10. Gates

### S1 — 1K
Baseline correctness and plan validation.

### S2 — 10K
Confirm index strategy and JSONB behavior remain stable.

### S3 — 100K
Mandatory review of composite/partial indexes, evidence bridge and JSONB access paths.

### S4 — 1M
Stress test. Any unexpected sequential scan, lock contention, pathological JSONB plan, or bridge-table degradation requires remediation before claiming scale readiness.

## 11. Pass criteria

A tier passes only if:

1. Referential and scope invariants remain intact.
2. Query plans remain index-supported where selective access is expected.
3. No critical deterministic field is forced into JSONB.
4. Evidence M:N retrieval remains bounded and predictable.
5. record_zone cardinality enforcement remains transactional.
6. Adding new zone/knowledge/source types does not create unnecessary destructive migrations.
7. No security boundary or provenance guarantee is weakened.

Exact latency thresholds will be defined after establishing the first controlled benchmark environment; they must not be invented before measurement.

## 12. Non-goals

This plan does not authorize:

- production migration
- production data import
- Google Sheets → Core import
- n8n Core write access
- Qdrant/RAG/KG/MCP implementation
- microservice decomposition
- premature partitioning/sharding

## 13. Approval gate

Status remains **PROPOSED** until the scale-test workload, synthetic-data generation strategy and benchmark environment are reviewed and approved by the Human Project Owner.

**Production migration remains BLOCKED.**
