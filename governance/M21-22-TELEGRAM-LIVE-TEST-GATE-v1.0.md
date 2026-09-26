# M21-22 — TELEGRAM LIVE TEST GATE v1.0

**Status:** LIVE TEST BLOCKED BY MISSING RUNTIME SECRET

## Objective
Provide a controlled, fail-closed transition from the deterministic Telegram adapter to one real Telegram delivery.

## Preconditions
1. Artifact status is `READY_FOR_DELIVERY` from M21.17.
2. Artifact MIME is `image/webp`.
3. Artifact SHA-256 exists.
4. Authorized destination is explicitly configured.
5. `TELEGRAM_BOT_TOKEN` exists only in runtime secret storage.
6. The test artifact is identified by a unique `render_id`.

## Safety Rules
- No token is committed to Git.
- No token is printed to logs.
- No live send occurs when the credential is absent.
- The first live test sends exactly one artifact to exactly one authorized destination.
- Repeating the same test uses the M21.20 idempotency key and must not duplicate the message.
- Telegram response is recorded as delivery metadata only; it never updates project truth.

## Current Evidence
Host check on 2026-09-26: `TELEGRAM_BOT_TOKEN` absent. Therefore no live Telegram message was sent.

M21.22 live gate harness: **2/2 PASS**.

## Live Test Procedure
When runtime secret injection is explicitly configured:
1. prepare one `READY_FOR_DELIVERY` WEBP;
2. inject `TELEGRAM_BOT_TOKEN` through runtime secret storage;
3. execute one outbound `sendDocument` request;
4. capture Telegram `message_id` without exposing token;
5. persist delivery receipt;
6. repeat the same delivery request;
7. verify idempotent no-duplicate behavior;
8. remove/rotate test secret according to deployment policy.

## Exit Criteria
`DELIVERED` with a Telegram message identifier plus verified idempotent repeat = M21.22 LIVE PASS.

Until then, status remains `BLOCKED_MISSING_CREDENTIAL` and must not be represented as a live PASS.
