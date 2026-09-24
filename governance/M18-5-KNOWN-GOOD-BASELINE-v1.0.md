# M18.5 — Known-Good Production Baseline v1.0

Status: VERIFIED — BASELINE FOR CONTROLLED ROLLBACK TEST

Date: 2026-09-24

## Production identity

- Service: `m18-runtime-gateway`
- Image: `runtime-m18-runtime-gateway:latest`
- Image digest: `sha256:9456ac1192c44642f1e4725255720660fb58b4d268ba41f19b3e5a4cd873f12c`
- Source commit: `f517c4455b50cce02b41b8681f04c10b6ccb173e`
- Model: `qwen3:1.7b`
- Agent: `specialist:qwen:security-evidence-analyst`

## Fresh runtime evidence

The current production deployment completed a fresh consecutive M18.5 delegation sequence:

- T01–T10: 10/10 PASS
- Each test returned `HUMAN_GATE`
- Each test returned `REVIEWED`
- Each test produced attributable correlation/evidence identity
- Runtime health was verified as healthy with no restart observed

Previously verified controls on the same runtime also include:

- normal HUMAN_GATE chain
- model `APPROVED` escape rejection
- artifact digest mismatch rejection
- independent recovery execution

## Rollback use

This identity is the explicitly recorded pre-mutation Known-Good Baseline for the controlled rollback test.

Rollback is not considered successful merely by restarting the same container. The rollback test must mutate the M18 runtime to a distinct deployment identity, then restore this exact image digest and source commit, followed by:

1. container/gateway health verification;
2. one controlled delegation smoke;
3. HUMAN_GATE / REVIEWED / evidence / correlation verification;
4. M17 regression verification.

No claim of rollback PASS is made by this baseline record alone.
