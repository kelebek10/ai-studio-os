# M18 — Agent Registry Non-Production Evidence v1.0

**Status:** PASS — non-production boundary only  
**Environment:** disposable PostgreSQL 16 database `paiforge_test` / container `paiforge_pg_test`  
**Migration:** `migrations/nonprod/014_m18_agent_registry_authority.sql`  
**Production mutation:** NONE

## Verified controls

- T01 PASS — `paiforge_m18_ai_provider` cannot INSERT a CORE agent.
- T02 PASS — `paiforge_m18_orchestrator` cannot INSERT a CORE agent; RLS rejects the row.
- T03 PASS — `paiforge_m18_human_approver` created `core:m18` with approval id `HUMAN-001`.
- T04 PASS — `paiforge_m18_orchestrator` created a QWEN specialist only under `core:m18`.
- T05 PASS — `paiforge_m18_ai_provider` cannot INSERT a SPECIALIST agent.
- T06 PASS — audit records bind CORE creation to `paiforge_m18_human_approver` and SPECIALIST creation to `paiforge_m18_orchestrator`.
- T07 PASS — 12 active CORE agents were accepted; the 13th was rejected with `CORE_AGENT_LIMIT_REACHED`.
- T08 PASS — existing M18 fail-closed runtime suite: `M18_FAIL_CLOSED_TESTS: PASS`.

## Boundary conclusion

The non-production registry now has a persistent PostgreSQL authority boundary: provider roles cannot provision agents; the Orchestrator role can provision only SPECIALIST rows; CORE creation is restricted to the dedicated human-approval role; and registry limits are enforced by database triggers. RLS is used to restrict insert shape by principal. PostgreSQL RLS `WITH CHECK` policies are a database-level control, not an application convention.

## Limitations

This evidence does **not** authorize production migration or production deployment. The production database currently has no M18 registry schema/roles. Human approval remains a separate control boundary and must not be simulated by the runtime.
