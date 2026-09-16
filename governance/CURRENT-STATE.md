# PEYZAJ AI / PAI-FORGE — CURRENT STATE

**Document:** CURRENT-STATE.md  
**Version:** 2.4  
**Status:** CONTROLLED BASELINE  
**Classification:** PROJECT CONTROL  
**Owner:** Human Project Owner  
**Location:** `governance/CURRENT-STATE.md`  
**Last Updated:** 2026-09-16

## Current Phase

**Phase:** Phase 1–3 Foundation — M15 Controlled Agent Runtime / Human Authorization Security Design

**Completed gates:**
- ADIM 1 — Repository & Governance Audit: GO
- ADIM 2 — Project Control / Governance Synchronization: GO
- PostgreSQL Blueprint v1.3: CONTROLLED RE-REVIEW PASS
- PostgreSQL final pre-approval test 001: PASS
- Human Project Owner approval: APPROVED FOR MIGRATION DESIGN
- M08 — State Transition: PASS
- M09 — Optimistic Concurrency: PASS
- M10 — Event Sequencing: PASS
- M11 — Idempotency Minimum Evidence: PASS
- M11 — Concurrent Retry: PASS
- M12 — Provenance Strengthening: PASS — independent provenance recomputation, payload tamper detection, chain-hash tamper detection and rollback integrity verified
- M13 — Candidate Boundary: PASS — authority, bypass, concurrency, provenance integrity and rollback evidence recorded
- M14 — Approval Authority: PASS — database principal/privilege enforcement verified; AI and workflow approval denied; authorized human approval accepted; provenance and stale/duplicate rejection verified
- M15 Stage 1 — Controlled Readiness Runtime Gate: PASS — O1/O2/O3/O4/O5 real runtime evidence verified

## M15 Stage 1 Evidence

- Evidence checkpoint commit: `79bccfed9519ddcfcb32069a5f15008d75c4bad8`.
- Canonical Control Agent source synchronized from `phase-1-3-foundation`.
- Canonical image: `paiforge-control-agent:canonical-20260915`.
- Immutable image digest verified: `sha256:76a480d27506b6fb6c6dd0dccd3ed89e9ed9ff17ac846cedbd33f5e82ff2395a`.
- Image platform: `linux/arm64`.
- Runtime health: `healthy`; runtime status `running`; restart count `0`.
- O1 REAL: PASS — database observation completed in `MODE=READ_ONLY`.
- O2 REAL: PASS — missing evidence produced `BLOCKED / MISSING_EVIDENCE`.
- O3 REAL: PASS — unknown task state produced `UNKNOWN / UNKNOWN_STATE`.
- O4 REAL: PASS — mutation attempt denied by PostgreSQL schema privilege boundary.
- O5 REAL: PASS — repeated valid observations produced identical deterministic fingerprint.
- Runner principal: `paiforge_runner_ro`; LOGIN enabled; SUPERUSER/CREATEDB/CREATEROLE disabled.
- Runner database privileges: CONNECT and schema USAGE allowed; database CREATE, TEMP and schema CREATE denied.
- Credential rotation completed after a credential exposure event; new credential verified against PostgreSQL and retained only server-side.
- Legacy runtime retained under rollback name; canonical runtime cutover completed without deleting the legacy container.
- No production migration, production SQL execution or data import was performed as part of this gate.

## M13 Evidence

- Six-check candidate boundary pilot: PASS.
- Independent provenance recomputation: PASS.
- Controlled payload and chain tamper detection: PASS.
- Two-session optimistic concurrency: Session A succeeded; stale Session B returned 0.
- Final candidate 1: `APPROVED / HUMAN_REVIEWER / version 2`.
- Final provenance: `valid=true`.
- Rollback candidate 2: `APPROVED / version 2` before rollback; `VERIFIED / version 1` after rollback.
- Final combined raw evidence SHA-256: `220eae739dd01d0369f5feffd5cfaaea7a6aa1d2803b52a438941e7ff700114b`.
- Governance record: `governance/M13-CANDIDATE-BOUNDARY-EXECUTION-RECORD-v1.0.md`.

## M14 Evidence

- Execution record: `governance/M14-APPROVAL-AUTHORITY-EXECUTION-RECORD-v1.0.md`.
- Test script: `migrations/nonprod/013_m14_approval_authority.sql`.
- Environment: disposable non-production PostgreSQL test database `paiforge_pg_test`.
- T01 PASS: AI principal denied by privilege boundary.
- T02 PASS: workflow principal denied by privilege boundary.
- T03 PASS: AI cannot self-assert human approval authority.
- T04 PASS: authorized human approval principal accepted.
- T05 PASS: approval state and principal provenance verified.
- T06 PASS: duplicate/stale approval rejected.
- Final test output: `M14 AUTHORITY TEST SUITE COMPLETE: T01-T06 PASS`.

## M15-A — Human Authorization Security Design

**Status: BLOCKED / DESIGN-AND-TEST GATE — NOT IMPLEMENTED**

The three independent adversarial reviews (Claude, Gemini and Copilot) identified a common need to strengthen the human authorization boundary before agent/workflow implementation and production mutation. Their findings are treated as design input; no AI verdict itself constitutes project approval.

### Pinned design decision

- Primary daily human authorization: **Passkey / WebAuthn**.
- Recovery: separate controlled recovery credential; PUK-like high-entropy recovery code is a candidate UX mechanism, not an unrestricted master key.
- Separate signing key remains an implementation alternative for recovery/break-glass and must be evaluated before final implementation.
- Telegram remains notification/communication only and is not an approval authority.
- NVIDIA remains an optional compute adapter and cannot become a Core mutation authority.
- GitHub review/approval is repository governance and does not by itself constitute the PAI-FORGE cryptographic Human Authorization Protocol.
- AI consensus is evidence/analysis only and cannot constitute human approval.

### Authorization payload baseline

`authorization_id + task_id + correlation_id + commit_sha + artifact_digest + action + nonce + issued_at + expires_at + human_identity + authorization_method`

### Authorization state machine

`ISSUED -> ACTIVE -> USED | EXPIRED | REVOKED`

Terminal states cannot return to ACTIVE. Nonce consumption must be atomic. Reuse/replay must be BLOCKED.

### Mandatory fail-closed conditions

Identity failure, scope mismatch, commit/artifact mismatch, invalid credential/signature, nonce replay, expiry, revocation, missing evidence, provenance mismatch, authority conflict, FAIL, UNKNOWN or TIMEOUT all map to **BLOCKED**.

### M15-A minimum acceptance criteria

AUTH-01 through AUTH-10 must all be proven by deterministic non-production runtime evidence and independent review. The detailed adversarial test contract is pinned in:

`governance/M15-A-HUMAN-AUTHORIZATION-ADVERSARIAL-TEST-MATRIX-v1.0.md`

### Additional adversarial coverage

ADV-01 through ADV-20 cover action/correlation tampering, payload tampering, expiry manipulation, conflict-round/task-ID bypass, agent/orchestrator/reviewer self-authorization, concurrent replay, artifact/provenance mismatch, missing evidence, FAIL/UNKNOWN promotion, rollback bypass, Telegram-as-authority, AI consensus-as-authority, workflow bypass and unsafe recovery.

### Pinned M15-A documents

- `governance/M15-A-HUMAN-AUTHORIZATION-THREAT-MODEL-v1.0.md`
- `governance/M15-A-HUMAN-AUTHORIZATION-ADVERSARIAL-TEST-MATRIX-v1.0.md`
- `governance/M15-A-AUTHORIZATION-PROTOCOL-DESIGN-v1.0.md`

## Authoritative PostgreSQL Artifacts

- `governance/POSTGRESQL-SCHEMA-BLUEPRINT-v1.3.md`
- `governance/POSTGRESQL-SCHEMA-REVIEW-v1.3.md`
- `governance/POSTGRESQL-SCHEMA-REVIEW-TEST-001.md`
- `governance/POSTGRESQL-SCHEMA-APPROVAL-v1.0.md`
- `governance/POSTGRESQL-MIGRATION-DESIGN-PLAN-v1.0.md`
- `governance/POSTGRESQL-MIGRATION-TEST-MATRIX-v1.0.md`
- `governance/POSTGRESQL-MIGRATION-SQL-SKELETON-v1.0.md`
- `governance/M08-STATE-TRANSITION-EXECUTION-RECORD-v1.0.md`
- `governance/M09-OPTIMISTIC-CONCURRENCY-EXECUTION-RECORD-v1.0.md`
- `governance/M10-EVENT-SEQUENCING-EXECUTION-RECORD-v1.0.md`
- `governance/M11-IDEMPOTENCY-MINIMUM-EVIDENCE.sql`
- `governance/M11-IDEMPOTENCY-MINIMUM-EVIDENCE-EXECUTION-RECORD-v1.0.md`
- `migrations/nonprod/010_m12_provenance_strengthening.sql`
- `governance/M12-PROVENANCE-STRENGTHENING-EXECUTION-RECORD-v1.0.md`
- `migrations/nonprod/011_m13_candidate_approval_boundary.sql`
- `migrations/nonprod/012_m13_authority_concurrency_provenance.sql`
- `governance/M13-CANDIDATE-BOUNDARY-EXECUTION-RECORD-v1.0.md`
- `migrations/nonprod/013_m14_approval_authority.sql`
- `governance/M14-APPROVAL-AUTHORITY-EXECUTION-RECORD-v1.0.md`
- `governance/M15-STAGE1-CONTROLLED-READINESS-EVIDENCE-v1.0.md`

## Migration Preconditions

1. Approved Blueprint is present and path/version identity is consistent.
2. Controlled schema review and final pre-approval test are PASS.
3. Human approval authorizes migration design only.
4. Migration design must preserve Core write authority, tenant isolation, immutability, provenance, concurrency and idempotency.
5. No production mutation is permitted at this gate.
6. M14 approval authority is technically enforced by database principal/privilege boundary in the tested non-production control.
7. M15 Stage 1 runtime readiness is PASS; subsequent M15 progression requires its own controlled evidence and applicable approval gate.
8. M15-A Human Authorization is not yet proven; no production authorization path may be inferred from M14 database approval tests.

## Design Principles

Structured-first → Semantic-second → LLM-last.

PostgreSQL/PostGIS is the trusted structured persistence layer. LLMs do not directly mutate Core. n8n remains outside the Core write boundary.

Human authority is a separate control plane from AI reasoning and repository automation.

## Immediate Next Actions

1. Freeze M15-A threat model, authorization payload, state machine and adversarial test contract.
2. Design the implementation contract: verification boundary, identity model, nonce/expiry/revocation/replay controls, recovery, and evidence schema.
3. Implement and test only in controlled non-production scope.
4. Obtain independent review and explicit Human Project Owner acceptance before progressing.
5. Do not enable production deployment/mutation, Telegram approval or NVIDIA Core mutation.

## Stop Conditions

Any unresolved security, integrity, authority, concurrency, idempotency, provenance or rollback failure blocks progression.

**Production migration, production SQL execution, data import, production deployment promotion and infrastructure mutation remain BLOCKED.**

**M15-A remains BLOCKED until AUTH-01..AUTH-10 and ADV-01..ADV-20 are executed with verifiable evidence and independently reviewed.**

**Source of Truth Rule:** Versioned repository governance records are the durable project control layer. Conversational context is not the sole authority.
