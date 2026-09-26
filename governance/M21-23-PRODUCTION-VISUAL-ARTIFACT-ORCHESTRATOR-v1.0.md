# M21-23 — PRODUCTION VISUAL ARTIFACT ORCHESTRATOR v1.0

**Status:** DETERMINISTIC PREFLIGHT VERIFIED

## Purpose
One coordination boundary for the visual artifact lifecycle. It never changes design truth.

## Flow
`READY_FOR_PROVIDER -> provider execution -> WEBP validation -> READY_FOR_DELIVERY -> Telegram`

## Gates
- invalid render request -> BLOCKED_RENDER_REQUEST
- missing artifact -> BLOCKED_MISSING_ARTIFACT
- artifact not ready -> delegated blocking state
- missing destination -> BLOCKED_MISSING_DESTINATION
- missing Telegram credential -> BLOCKED_MISSING_CREDENTIAL

## Authority
The orchestrator coordinates existing contracts. It does not redesign geometry, alter layout or lighting, approve invalid artifacts, or infer measurements.

## Acceptance
M21.23 deterministic preflight: **5/5 PASS**.
