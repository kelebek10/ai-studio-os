# PAI-FORGE — GITHUB STATE RECONCILIATION / M18.5

**Status:** CONTROLLED / VERIFIED RECONCILIATION  
**Date:** 2026-09-24  
**Repository:** `kelebek10/ai-studio-os`  
**Branch:** `phase-1-3-foundation`  
**Coordinator:** GPT-5.6 Luna

## 1. Purpose

This document reconciles the GitHub source state with the live runtime before further M18.5 development.

M16 is immutable and remains:

**M16 = VERIFIED / CLOSED / ARCHIVED**

No M16 work is reopened by this reconciliation.

## 2. GitHub state

Verified GitHub branch:

`phase-1-3-foundation`

Verified remote branch HEAD:

`33cbef28f4208219c5dd863303e4758346e9b3ae`

HEAD commit:

`docs(m18.5): record delegation progress and next-session handoff`

The immediately preceding commit is:

`dbb0cfea8dd303a2dc1cdec9c9dc0de9de7c01f0`

The HEAD delta is the controlled M18.5 handoff document:

`governance/NEXT-SESSION-M18.5-HANDOFF-v1.0.md`

No evidence was found that this reconciliation requires rewriting M16 artifacts.

## 3. Local runtime checkout state

Remote host checkout at:

`/home/ubuntu/ai-studio-os`

was verified on device `peyzaj-ai`.

Observed local Git state:

- branch: `phase-1-3-foundation`
- local HEAD: `dbb0cfea8dd303a2dc1cdec9c9dc0de9de7c01f0`
- untracked: `runtime/__pycache__/`
- untracked: `runtime/communication/__pycache__/`

Therefore there is a **documentation/source-checkout drift of one commit** between the live host checkout and the GitHub branch HEAD.

The GitHub-only commit is the M18.5 handoff document. It does not itself establish runtime capability.

The untracked Python cache directories are runtime artifacts and are not treated as source-of-truth.

## 4. Runtime verification date

Runtime verification performed:

**2026-09-24**

Device:

`peyzaj-ai`

Device status was available and the production services were inspected directly.

## 5. Verified runtime services

The following services were observed running:

- `m18-runtime-gateway` — UP / healthy
- `m17-runtime-gateway` — UP
- `paiforge-agent-runner` — UP
- `paiforge-control-agent` — UP / healthy
- `paiforge-control-agent-canary` — UP / healthy
- `peyzaj_postgres` — UP / healthy
- `peyzaj_pgbouncer` — UP
- `paiforge_ollama` — UP
- `peyzaj_n8n_main` — UP
- `peyzaj_redis` — UP

The legacy production agent-runner remains a separate health/runtime compatibility component.

## 6. M18 Runtime Gateway — VERIFIED

Runtime container:

`m18-runtime-gateway`

Verified:

- status: `running`
- Docker health: `healthy`
- container user: UID `10001`
- host port publication: none
- internal port: `8091/tcp`

Repository implementation verified:

`runtime/m18_production_gateway.py`

The gateway:

- requires `M18_DATABASE_DSN`
- requires `M18_AGENT_ID`
- requires `M18_SOURCE_COMMIT`
- uses `PersistentAgentRegistry`
- requires an ACTIVE registered QWEN specialist
- uses `qwen3:1.7b` by default
- exposes `/health` and `/governance`
- accepts only `prompt` and `requires_human` at `/task`
- rejects undeclared authority/control fields
- keeps approval authority human-only

Supporting implementation files verified:

- `runtime/persistent_agent_registry.py`
- `runtime/agent_registry.py`
- `runtime/provider_contract.py`
- `runtime/orchestrator.py`
- `runtime/orchestrator_pipeline.py`
- `runtime/model_adapter.py`
- `runtime/ollama_provider.py`

## 7. Core Agent — VERIFIED IN PRODUCTION REGISTRY

Production PostgreSQL registry was queried directly.

Verified active hierarchy:

### Core

`core:security-intelligence`

Tier:

`CORE`

Approval:

`HUMAN-20260924-CORE-001`

### Specialist

`specialist:qwen:security-evidence-analyst`

Tier:

`SPECIALIST`

Provider:

`QWEN`

Parent:

`core:security-intelligence`

Therefore the Core Agent is **not inferred from code**; it is present in the live production registry.

Its authority remains bounded. No new authority is granted by this document.

## 8. Security / Intelligence enforcement boundary — VERIFIED AT ENFORCEMENT LAYER

The security/intelligence concept is represented by the approved Core Agent and bounded specialist, but it is **not** declared an unrestricted autonomous authority.

Verified repository controls include:

- provider contracts deny `APPROVE`
- provider contracts deny `PROVISION`
- Core creation requires HUMAN approval
- Specialist creation requires Orchestrator authority and a Core parent
- persistent registry authority is enforced by database principals/RLS
- Human Gate remains required for protected decisions
- HTTP callers cannot submit authority controls
- M14 approval authority remains outside AI/provider authority

Verified production security tests recorded before this reconciliation:

- runtime Core insertion denied by RLS
- runtime audit forgery denied
- AI provider registry INSERT denied
- `approve=true` HTTP control denied with `403 CONTROL_FIELD_FORBIDDEN`

The Security/Intelligence layer is therefore verified as an **enforcement/bounded-agent boundary**, not as an independent approval authority.

## 9. M17 status

M17 is:

**CLOSED — 4/4 PASS**

Verified GitHub closeout:

`governance/M17-CLOSEOUT-v1.0.md`

M17 milestones:

- M17.1 Controlled Runtime Loop — PASS
- M17.2 Live Qwen3 Mission Loop — PASS
- M17.3 Qwen3 → Reviewer → Evidence → Security — PASS
- M17.4 Telegram → Runtime → Qwen3 → Result → Telegram — PASS

M17 must not be reopened.

Live runtime verification also shows:

- `m17-runtime-gateway`: running
- restart count: 0

## 10. M18 status

M18 is:

**OPEN**

Verified GitHub artifacts include:

- `governance/M18-AGENT-GOVERNANCE-v1.0.md`
- `governance/M18.3-PRODUCTION-CONVERGENCE-v1.0.md`
- `runtime/m18_production_gateway.py`
- `runtime/persistent_agent_registry.py`
- `runtime/agent_registry.py`
- `runtime/provider_contract.py`
- production-safe registry migration:
  `migrations/nonprod/015_m18_production_safe_registry.sql`

M18 production runtime is demonstrably deployed and healthy.

The non-production destructive migration `014_m18_agent_registry_authority.sql` remains prohibited for production.

## 11. M18.5 status

M18.5 is:

**CLOSED / VERIFIED**

Verified:

- real production delegation completed
- result reached `HUMAN_GATE`
- review state was `REVIEWED`
- evidence digest was produced
- Human Gate remained active
- 30/30 health stability checks were previously recorded as PASS
- forbidden `approve=true` control was blocked

Not yet verified:

- 10/10 consecutive delegation criterion — VERIFIED
- recovery criterion — VERIFIED
- full controlled rollback/restore criterion — VERIFIED
- final M17 regression after rollback — VERIFIED
- M18.5 closeout — VERIFIED

## 12. State drift explanation

The reported drift is real but narrower than initially indicated.

### Drift A — MASTER checkpoint

`governance/MASTER-RESUME-CHECKPOINT.md`

still contains the historical M16/M17 pre-flight state.

It is stale relative to the verified M17/M18 runtime.

This reconciliation intentionally does **not** overwrite that protected master document.

Reason: the requested controlled procedure is to establish a separate reconciliation checkpoint first, preventing an unverified runtime state from being promoted directly into the master source-of-truth.

### Drift B — live host Git checkout

The production host checkout is at:

`dbb0cfea8dd303a2dc1cdec9c9dc0de9de7c01f0`

while GitHub branch HEAD is:

`33cbef28f4208219c5dd863303e4758346e9b3ae`

The difference is the handoff documentation commit. Runtime evidence was independently verified and is not treated as proof merely because the GitHub document says it exists.

### Drift C — runtime database state

The production registry contains the Core and Specialist hierarchy even though these identities are not hard-coded into repository source.

This is expected persistent runtime state, but it must remain attributable to the Human approval record and database audit/provenance.

## 13. M16 protection

This reconciliation does not modify or reopen M16.

Protected rule:

**M16 = VERIFIED / CLOSED / ARCHIVED**

Any suspected M16 regression must first produce fresh evidence and an explicit change request.

## 14. Used commit SHAs

Relevant verified commits:

- M16 final evidence package:
  `8cb0b4ee5faae151a1f52bc41287bfd8cf1d35f4`
- M17 runtime/governance history includes:
  `b82d981`
  `3b1a479`
  `c09afe3`
- M18 persistent registry:
  `87978dd`
- M18.2 live Qwen E2E:
  `c171699f404d54ff20978b02384c5494154eb0bc`
- M18 production gateway non-root:
  `881a26b`
- M18 production registry hardening:
  `83be915791167c8e3cb4208a297f5ff9fba35aba`
- M18.3 convergence:
  `58908bd1af781905f858873fe3361efa428bada`
- M18.5 handoff:
  `33cbef28f4208219c5dd863303e4758346e9b3ae`

## 15. M18.5 Closeout Evidence

Controlled rollback/restore and post-rollback M17 regression are recorded in:

`governance/M18-5-ROLLBACK-EXECUTION-2026-09-24.md`

Known-good production identity restored exactly:

- image digest: `sha256:9456ac1192c44642f1e4725255720660fb58b4d268ba41f19b3e5a4cd873f12c`
- source commit: `f517c44`
- health: `healthy`
- restart count: `0`

M17 post-rollback regression returned HTTP 200 / COMPLETED / REVIEWED / VERIFIED with correlation `0948c7bb-6f9b-4e35-b57a-534fdf994343`.

## 16. Next controlled step

No new M18.5 feature development is authorized by this reconciliation itself.

The verified starting point is:

**M16 CLOSED → M17 VERIFIED/CLOSED → M18 PRODUCTION VERIFIED → M18.5 CONTROLLED START**

The next M18.5 action is the independent single-task delegation validation, followed by recovery, conflict, rollback and M17 regression testing.

## 17. Stop conditions

STOP if:

- GitHub and runtime identities become contradictory
- Core approval provenance cannot be demonstrated
- Security boundary becomes writable by AI/provider
- Human approval authority changes
- M14 boundary changes
- M18 exposes an unexpected host port
- M17 is modified
- production migration becomes necessary without an explicit approved gate
- a PASS cannot be backed by real runtime evidence
