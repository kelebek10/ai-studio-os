# M14 — Approval Authority Execution Record v1.0

**Status:** PASS  
**Environment:** disposable non-production PostgreSQL test database (`paiforge_pg_test`)  
**Branch:** `phase-1-3-foundation`  
**Test script:** `migrations/nonprod/013_m14_approval_authority.sql`  

## Objective

Verify that approval authority is enforced by the actual PostgreSQL principal and privilege boundary, not by caller-supplied actor metadata.

## Execution result

- T01 PASS — AI principal denied by privilege boundary.
- T02 PASS — workflow principal denied by privilege boundary.
- T03 PASS — AI cannot self-assert human approval authority.
- T04 PASS — authorized human approval principal accepted.
- T05 PASS — approval state and principal provenance verified.
- T06 PASS — duplicate/stale approval rejected.

Final output:

`M14 AUTHORITY TEST SUITE COMPLETE: T01-T06 PASS`

## Authority conclusion

`paiforge_m14_human_approver` is the only principal granted approval-function EXECUTE privilege. The approval function is `SECURITY INVOKER` and performs the state mutation under the actual calling principal. The human approval principal has the required `SELECT, UPDATE` privilege on the disposable candidate table. AI and workflow principals do not receive approval EXECUTE privilege.

## Scope / limitations

This is a non-production authority test only. It does not authorize production migration, production data mutation, infrastructure mutation, or deployment.

## Decision

M14 PASS. The authority gate is technically enforced for the tested non-production boundary. Subsequent governance work must preserve this principal/privilege-based authority model.
