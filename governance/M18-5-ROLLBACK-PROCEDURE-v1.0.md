# M18.5 Controlled Rollback Procedure v1.0

Status: DEFINED — NOT YET EXECUTED

Purpose: define a deterministic rollback path without mutating production during design.

## Preconditions
- M18 current deployment identity is recorded by commit SHA and image digest.
- A known-good M18 deployment identity is recorded before any rollback.
- Human gate is required for the deployment mutation.

## Sequence
1. Capture current deployment identity and health evidence.
2. Select the explicitly recorded known-good image/commit.
3. Human gate authorizes the rollback mutation.
4. Deploy only the known-good identity.
5. Verify container health and gateway health.
6. Execute one controlled delegation smoke test.
7. Verify HUMAN_GATE, review state, evidence digest and correlation ID.
8. Record rollback evidence and the resulting deployment identity.
9. Restore the pre-rollback deployment only through another explicit human gate if restoration is required.

## Fail-closed conditions
- Missing known-good identity => BLOCKED.
- Missing human authorization => BLOCKED.
- Health failure => BLOCKED.
- Delegation smoke failure => BLOCKED.
- Evidence/correlation failure => BLOCKED.

## Rule
Restarting a container is not considered rollback. A rollback is valid only when the deployment identity changes to the recorded known-good identity and the post-rollback evidence chain passes.
