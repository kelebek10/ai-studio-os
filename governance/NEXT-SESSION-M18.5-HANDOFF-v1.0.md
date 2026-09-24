# PEYZAJ AI — M18.5 NEXT SESSION HANDOFF

## Model / project
Coordinator: GPT-5.6 Luna.
Repository: `kelebek10/ai-studio-os`.
Branch: `phase-1-3-foundation`.

## Hard state
- M16 CLOSED. Do not reopen.
- M17 CLOSED. Do not reopen unless explicit defect/change request.
- M18 OPEN.
- Current section: M18.5 — real production E2E + delegation/security/rollback validation.
- M18.6 has NOT started and must not be declared ready yet.

## M18 Core Agent / Security Intelligence
Production registry now contains the first approved hierarchy:
- Core Agent: `core:security-intelligence`
- Name: PAIFORGE Security & Intelligence Core
- Scope: security monitoring, evidence analysis, anomaly detection, runtime audit, incident alerting, human-gate escalation.
- Human approval: `HUMAN-20260924-CORE-001`
- Specialist: `specialist:qwen:security-evidence-analyst`
- Provider: QWEN
- Parent: `core:security-intelligence`

Authority rules remain:
- Core creation is HUMAN-only.
- Specialist provisioning is Orchestrator-only under an approved Core.
- AI providers cannot create/write registry agents.
- Agents cannot approve their own work.
- Critical actions remain HUMAN_GATE.

## Production M18 runtime
- Service: `m18-runtime-gateway`
- Model: `qwen3:1.7b`
- Runs non-root as UID 10001.
- No host port published.
- Networks: `peyzaj_production_peyzaj_net` + `ollama_default`.
- Production DB role: `paiforge_m18_runtime`.
- PgBouncer is used for the M18 DB connection.
- Production registry schema: `m18_agent_registry`.
- Migration used: `migrations/nonprod/015_m18_production_safe_registry.sql`.
- Do NOT use migration 014 in production.

## Verified production security evidence
- Dedicated M18 DB role is NOSUPERUSER / NOCREATEDB / NOCREATEROLE.
- Runtime Core insertion denied by RLS.
- Runtime audit forgery denied.
- AI provider INSERT denied.
- `approve=true` HTTP field returns `403 CONTROL_FIELD_FORBIDDEN`.
- M18 gateway health is currently stable.
- 30 consecutive local `/health` checks: PASS.
- M18 gateway restart count: 0 at last verification.
- M17 runtime gateway: RUNNING, restart count 0 at last verification.

## Real production delegation evidence
A real M18 production task completed:
- HTTP 200
- status: `HUMAN_GATE`
- review: `REVIEWED`
- evidence digest: `a779bea0f349674d6d5613ccc2676e6594b60142c8d7f79f93ce52eb5ee422b8`
- human_gate: true
- correlation ID: `a2d467b4-9d75-40b6-a558-74bbf0921a63`

Earlier controlled delegation attempts were started, but the requested 10/10 consecutive delegation criterion has NOT been achieved and must NOT be reported as PASS.
A long-running batch was aborted because it interacted poorly with the gateway health timing. The methodology was changed to independent single-task tests.

## Latest stability finding
A transient connection-refused event occurred during an independent test. Investigation showed the gateway subsequently remained healthy.
Verified after the event:
- 30/30 health checks PASS.
- Gateway restart count 0.
- New single production delegation PASS.
- Forbidden control field test PASS.
The transient event must remain documented; do not erase it from QA history.

## Next exact work
1. Continue M18.5 with independent single-task delegation tests.
2. Record each real PASS; target 10/10 consecutive successful delegations.
3. After delegation criterion is met, test recovery.
4. Test conflict limit and fail-closed behavior.
5. Test rollback by removing only M18 and verifying M17 remains healthy.
6. Run M17 regression without modifying/reopening M17.
7. Only with real evidence, close M18.5.
8. Then begin M18.6 final audit / delegation readiness.

## Do not do
- Do not claim 10/10 delegation PASS yet.
- Do not create another Core Agent automatically.
- Do not reopen M17 or M16.
- Do not expose a host port for M18.
- Do not weaken Human Gate.
- Do not store production secrets in GitHub.
- Do not report PASS without real runtime evidence.

## Session style
Use: DURUM → KARAR → SONRAKİ ADIM.
Keep updates concise. Perform checks first. Preserve real evidence and failures.
