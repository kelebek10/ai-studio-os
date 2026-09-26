# M21-19 — E2E RENDER PIPELINE v1.0

**Status:** MOCK E2E VERIFIED

## Objective
Connect the M21.16 render request, M21.18 FLUX provider boundary and M21.17 WEBP validation into one fail-closed pipeline.

## Canonical flow
`READY_FOR_RENDER → READY_FOR_PROVIDER → provider submit → polling → READY_FOR_OUTPUT_VALIDATION → WEBP validation → READY_FOR_DELIVERY`

## Mock verification
The deterministic mock path proves the orchestration without spending provider credits:
- request accepted only from `READY_FOR_RENDER`;
- polling URL is consumed as returned;
- provider `Processing` remains pending;
- provider `Ready` requires a result sample URL;
- artifact is persisted before validation;
- layout digest, lighting digest and scene identity remain unchanged;
- artifact SHA-256 is recorded;
- provider output never updates project truth.

## Real-provider gate
Real execution is blocked unless `BFL_API_KEY` is present in the runtime environment. The key is never written to files, project artifacts, Git, Telegram or logs.

## Delivery gate
M21.17 remains authoritative. Only `READY_FOR_DELIVERY` can proceed to Telegram/customer delivery.

## Acceptance
M21.19 mock E2E: 8/8 PASS.

## Next
M21.20 — Telegram delivery adapter with delivery receipt, artifact identity and fail-closed retry policy.
