# M18.5 Controlled Rollback Execution — 2026-09-24

Status: VERIFIED — ROLLBACK/RESTORE COMPLETE
Human Gate: Explicit rollback authorization received before production mutation.

## Known-Good Baseline
- Service: `m18-runtime-gateway`
- Image: `runtime-m18-runtime-gateway:latest`
- Digest: `sha256:9456ac1192c44642f1e4725255720660fb58b4d268ba41f19b3e5a4cd873f12c`
- Source commit: `f517c44`
- Model: `qwen3:1.7b`

## Controlled Rollback Attempt
The first historical candidate (`paiforge-m18-production-candidate:convergence`, digest `sha256:bbca6ce156e30dad5d9f01650f1e4ba7fda85cee17cd0d88750448531621c8fc`) passed preflight health but its production delegation smoke timed out after 140s. It was not accepted as a rollback PASS and was removed. The known-good deployment was restored and verified healthy.

A second distinct candidate was then selected after preflight:
- Image: `runtime-m18-runtime-gateway-smoke:latest`
- Digest: `sha256:47d7dd9f1540127601957e4574e4d37c9d8c22e94f20c6dcd0912992669f05a3`
- Preflight health: HTTP 200

## Successful Rollback Candidate Validation
- Candidate deployed under the production service identity.
- Candidate health: HTTP 200.
- Controlled `/task` delegation smoke: HTTP 200.
- Status: `HUMAN_GATE`
- Review: `REVIEWED`
- `human_gate`: `true`
- Evidence digest: `d923c8fa95fda66cc61e14b36a157382e6286010f5d788e0df5cadcea66cd09c`

## Exact Restore
The production service was restored to the recorded known-good identity:
- Image digest: `sha256:9456ac1192c44642f1e4725255720660fb58b4d268ba41f19b3e5a4cd873f12c`
- Source commit: `f517c44`
- Container status: running
- Health: healthy
- Restart count: 0
- Direct health endpoint: HTTP 200

## M17 Regression After Restore
M17 was not modified. Fresh regression request returned:
- HTTP 200
- Status: `COMPLETED`
- Review: `REVIEWED`
- Evidence: `VERIFIED`
- Correlation ID: `0948c7bb-6f9b-4e35-b57a-534fdf994343`
- Runtime: 23.07s
- M17 container restart count remained 0.

## Closure Decision
Both required fresh runtime gates are now evidenced: controlled rollback/restore and post-rollback M17 regression. M18.5 may be closed. M18.6 is the next controlled stage.
