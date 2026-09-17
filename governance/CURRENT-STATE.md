# PEYZAJ AI / PAI-FORGE — CURRENT STATE

**Document:** CURRENT-STATE.md  
**Version:** 2.5  
**Status:** CONTROLLED BASELINE  
**Classification:** PROJECT CONTROL  
**Owner:** Human Project Owner  
**Location:** `governance/CURRENT-STATE.md`  
**Last Updated:** 2026-09-17

## Current Phase

**Phase:** Phase 1–3 Foundation — M15-A Human Authorization Security / Deterministic Control Boundary

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

## M15-A — Current Gate

**Status: BLOCKED / DESIGN-AND-TEST GATE — NOT READY**

Independent adversarial review returned **PASS WITH CHANGES** and identified four P0 items plus P1/P2 hardening requirements. These findings are now incorporated into the controlled design baseline.

### P0 requirements now pinned

- **P0-1 Blind Signing / WYSIWYS:** critical authorization must present a human-readable action/target/binding summary before confirmation; displayed summary and executed action must be cryptographically/structurally bound; mismatch => BLOCKED.
- **P0-2 Prompt Injection:** untrusted PR/issue/commit/external content is data only; it cannot modify policy, scope, authority or permissions; adversarial injection must be tested.
- **P0-3 Deterministic Control:** Control is a non-AI deterministic policy-enforcement component. LLM output, AI consensus, model confidence and prompt interpretation cannot be authorization dependencies. Contract pinned in `governance/M15-A-CONTROL-DETERMINISM-CONTRACT-v1.0.md`.
- **P0-4 Recovery Security:** recovery cannot be an unrestricted static master key; final implementation must enforce replay protection, rotation/single-use semantics, controlled delay/notification and defined second-factor/cancellation semantics.

### P1 requirements

- **P1-1 Supervisor stop authority:** stop/DoS capability must be explicitly scoped, logged and independently reviewable.
- **P1-2 Core network isolation:** Core/PostgreSQL/Redis must be technically isolated from direct external access; exact network/firewall/SSH/reverse-proxy boundaries must be documented and tested.
- **P1-3 Supply-chain/branch bypass:** repository governance must prevent administrator/automation bypass of required security controls within supported GitHub capabilities.
- **P1-4 AI mock drift:** isolated periodic shadow tests may be used to detect real-provider behavior drift without making AI APIs an authorization dependency.
- **P1-5 Conflict lineage:** new task/correlation IDs must not reset conflict rounds for the same logical request; lineage/hash enforcement must be deterministic.

### P2 hardening

- Evidence tamper-evidence/hash-chain requirements.
- Artifact signing and provenance (e.g. Sigstore/cosign) where appropriate.
- NVIDIA adapter filesystem/secret isolation evidence.
- Self-hosted ARM64 runner security, if such a runner is later introduced.

## M15-A P0-3 — Deterministic Control Contract

**Status: OPEN — DESIGN PINNED / IMPLEMENTATION NOT YET PROVEN**

Pinned contract:

`governance/M15-A-CONTROL-DETERMINISM-CONTRACT-v1.0.md`

Required tests:

- CTRL-01 — deterministic repeated evaluation/fingerprint
- CTRL-02 — AI output substitution has no authority
- CTRL-03 — UNKNOWN/FAIL/missing/timeout fail closed
- CTRL-04 — controlled runtime reproducibility
- CTRL-05 — deterministic Control does not bypass independent mutation boundary

P0-3 cannot be marked PASS from documentation alone. Real non-production runtime evidence and independent review are required.

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

## M15-A Controlled Documents

- `governance/M15-A-HUMAN-AUTHORIZATION-THREAT-MODEL-v1.0.md`
- `governance/M15-A-HUMAN-AUTHORIZATION-ADVERSARIAL-TEST-MATRIX-v1.0.md`
- `governance/M15-A-AUTHORIZATION-PROTOCOL-DESIGN-v1.0.md`
- `governance/M15-A-CONTROL-DETERMINISM-CONTRACT-v1.0.md`

## Migration Preconditions

1. Approved Blueprint is present and path/version identity is consistent.
2. Controlled schema review and final pre-approval test are PASS.
3. Human approval authorizes migration design only.
4. Migration design must preserve Core write authority, tenant isolation, immutability, provenance, concurrency and idempotency.
5. No production mutation is permitted at this gate.
6. M14 approval authority is technically enforced by database principal/privilege boundary in the tested non-production control.
7. M15 Stage 1 runtime readiness is PASS; subsequent M15 progression requires its own controlled evidence and applicable approval gate.
8. M15-A Human Authorization is not yet proven; no production authorization path may be inferred from M14 database approval tests.
9. P0-1 through P0-4 and required P1 security boundaries must be proven before READY.

## Design Principles

Structured-first → Semantic-second → LLM-last.

PostgreSQL/PostGIS is the trusted structured persistence layer. LLMs do not directly mutate Core. n8n remains outside the Core write boundary.

Human authority is a separate control plane from AI reasoning and repository automation.

Control is deterministic policy enforcement, not an AI decision-maker.

Untrusted natural-language content cannot create authority or expand scope.

## Immediate Next Actions

1. Implement controlled non-production P0-3 deterministic Control contract.
2. Execute CTRL-01..CTRL-05 and record real runtime evidence.
3. Freeze/implement P0-1 human-readable authorization presentation and AUTH-11.
4. Freeze/implement P0-2 prompt-injection isolation and INJ-01.
5. Finalize recovery security contract and REC-01/REC-02.
6. Design and test Core network isolation (P1-2).
7. Only after the above, execute the second independent adversarial review.

## Stop Conditions

Any unresolved security, integrity, authority, concurrency, idempotency, provenance or rollback failure blocks progression.

**Production migration, production SQL execution, data import, production deployment promotion and infrastructure mutation remain BLOCKED.**

**M15-A remains BLOCKED until AUTH-01..AUTH-11, ADV-01..ADV-20 and the newly pinned CTRL/INJ/REC/NET/CONF tests are executed with verifiable evidence and independently reviewed.**

**Source of Truth Rule:** Versioned repository governance records are the durable project control layer. Conversational context is not the sole authority.
