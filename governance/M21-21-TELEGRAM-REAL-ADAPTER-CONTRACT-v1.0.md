# M21-21 — TELEGRAM REAL DELIVERY ADAPTER v1.0

**Status:** CONTRACT VERIFIED — NO PRODUCTION SEND

## Boundary
M21.21 converts a `READY_FOR_DELIVERY` WEBP artifact into a Telegram transport request. It does not alter project truth and does not decide whether an artifact is design-correct.

## Existing Gateway Separation
`runtime/telegram_gateway.py` remains the untrusted Telegram ingress. M21.21 is outbound delivery only. The two paths must not share authority.

## Telegram Method
The adapter targets Telegram Bot API `sendDocument` for WEBP artifact transport. The bot token is read only from `TELEGRAM_BOT_TOKEN` at runtime.

## Credential Gate
Missing or empty token -> `BLOCKED_MISSING_CREDENTIAL`. Tokens are never persisted in artifacts, source, Git, Telegram messages, or logs.

## Input Gates
- status must be `READY_FOR_DELIVERY`;
- MIME must be `image/webp`;
- SHA-256 must be present;
- destination must be present.

## Idempotency
Delivery identity is `destination + render_id + sha256`. A repeated request must reuse the existing receipt and must not create a duplicate send.

## Transport States
`READY_FOR_TELEGRAM`
`DELIVERED`
`BLOCKED_MISSING_CREDENTIAL`
`BLOCKED_ARTIFACT_NOT_READY`
`BLOCKED_INVALID_ARTIFACT`
`BLOCKED_MISSING_DESTINATION`
`BLOCKED_TRANSPORT_ERROR`
`BLOCKED_RETRY_EXHAUSTED`

## Production Rule
M21.21 test mode uses a synthetic token only. No real Telegram message is sent by this milestone. Production token injection requires an explicit deployment action and a subsequent controlled live test.

## Acceptance
M21.21 Telegram adapter contract: 5/5 PASS.
Existing M16.10 ingress gateway: PASS.
