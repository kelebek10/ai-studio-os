# M18.6 Final Audit v1.0

**Status:** OPEN — CONTROLLED AUDIT START
**Date:** 2026-09-24
**Branch:** `phase-1-3-foundation`
**Baseline commit:** `c26f0796e79b1fc3a01b6b16465c3701d5cdca23`

## Entry Gate
M18.5 is closed with fresh rollback/restore and post-rollback M17 regression evidence. M18.6 is read-only unless a separate controlled mutation gate is explicitly required.

## Initial Runtime Audit — 2026-09-24

### M18
- container: `m18-runtime-gateway`
- image digest: `sha256:9456ac1192c44642f1e4725255720660fb58b4d268ba41f19b3e5a4cd873f12c`
- source commit: `f517c44`
- status: `running`
- Docker health: `healthy`
- restart count: `0`
- container user: UID `10001`
- host port publication: none (`8091/tcp` internal only)
- `/health`: HTTP 200
- `/governance`: `approval=human_only`, `agent_creation=no_http_authority`

### M17
- container: `m17-runtime-gateway`
- status: `running`
- restart count: `0`
- M17 was not modified during M18.5 rollback/restore.

## Audit Scope
1. Deployment identity and reproducibility.
2. Human Gate enforcement and approval authority.
3. Provider/model authority boundaries.
4. Database/RLS authority boundaries.
5. Evidence/provenance integrity.
6. Network exposure and container hardening.
7. M17 non-regression.
8. Documentation/source/runtime reconciliation.

## Rule
No audit PASS is recorded without fresh runtime evidence. M18.6 does not reopen M16 or M17.

## Next Controlled Action
Run the read-only M18.6 final audit checks against the restored known-good production identity.

## Authority Boundary Result — 2026-09-24

**PASS — PROVISIONING BOUNDARY VERIFIED**

- Production DB runtime principal: `paiforge_m18_runtime`.
- Runtime principal is non-superuser, cannot create roles, cannot create databases, and does not bypass RLS.
- Runtime principal is intentionally a member of `paiforge_m18_orchestrator`; this is the controlled orchestration authority for specialist creation.
- Current runtime principal is not a member of `paiforge_m18_ai_provider` and not a member of `paiforge_m18_human_approver`.
- Registry RLS policies expose INSERT only to `paiforge_m18_orchestrator` for bounded SPECIALIST rows and to `paiforge_m18_human_approver` for CORE rows requiring a non-empty approval_id.
- Provider role has SELECT only; no INSERT policy exists for `paiforge_m18_ai_provider`.
- HTTP production gateway exposes no agent-creation/provisioning endpoint; `/governance` reports `agent_creation=no_http_authority`.
- Runtime `/task` accepts only `prompt` and `requires_human`; control fields are rejected.
- Model boundary rejects model output `APPROVED` with `MODEL_CANNOT_ASSERT_APPROVAL`.

### Architectural interpretation

Specialist provisioning is intentionally an **orchestrator capability**, not an AI-provider capability and not an HTTP caller capability. Core-agent creation remains human-approval-bound. This is consistent with the M18 authority model and is not a newly discovered governance defect.

## M18.6 Gate Status

All currently defined read-only entry checks are verified. No production mutation is required by this audit checkpoint.

**M18.6 remains OPEN pending final evidence aggregation and closeout commit.**
