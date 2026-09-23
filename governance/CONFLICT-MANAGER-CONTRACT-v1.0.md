# PAI-FORGE — M16.9 CONFLICT MANAGER CONTRACT v1.0

**Status:** IMPLEMENTED / TESTED IN CONTROLLED RUNTIME
**Scope:** M16.9 non-production runtime

For one `logical_problem_id`, substantive conflict resolution has exactly three automatic rounds. The logical problem ID is the immutable anchor; changing task ID, agent, model, workflow or channel cannot reset the counter.

## Controls

1. A conflict requires a non-empty `logical_problem_id`.
2. Rounds 1–3 are permitted only when scope and actionability checks pass.
3. Round 4 deterministically becomes `BLOCKED`.
4. Once closed, the same logical problem cannot reopen through a new task or model.
5. Missing lineage fails closed.
6. Scope/actionability failure blocks immediately and records the reason.
7. Conflict records preserve logical problem, task, agent, model, round and terminal reason.
8. The manager has no authority to extend the three-round limit.

## Persistence

The M16.9 non-production implementation uses an injected SQLite ledger so a manager process restart cannot reset an existing logical problem. The storage adapter is isolated from the manager contract and can be replaced by the project PostgreSQL persistence layer before production.
