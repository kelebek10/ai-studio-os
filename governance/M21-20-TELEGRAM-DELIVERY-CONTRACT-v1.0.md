# M21-20 — TELEGRAM DELIVERY CONTRACT v1.0

**Status:** MOCK VERIFIED

## Purpose
Deliver only validated visual artifacts to an authorized Telegram destination without changing project truth.

## Input Gate
Delivery requires `READY_FOR_DELIVERY` from M21.17. The adapter rejects provider-pending, rendered-but-unvalidated, malformed, or digest-mismatched artifacts.

## Idempotency
Canonical delivery key:
`destination + render_id + artifact_sha256`

A repeated request with the same key returns the existing receipt and must not send a duplicate Telegram message.

## Receipt
Each delivery records `delivery_id`, `render_id`, `status`, `attempts`, `telegram_message_id` when delivered, and `error_code` when blocked or failed.

## States
`READY_FOR_TELEGRAM -> DELIVERED`

Blocking states:
`BLOCKED_ARTIFACT_NOT_READY`
`BLOCKED_INVALID_ARTIFACT`
`BLOCKED_MISSING_DESTINATION`
`BLOCKED_TRANSPORT_ERROR`
`BLOCKED_RETRY_EXHAUSTED`

## Retry
Transport failures may retry with bounded attempts. Retries reuse the same idempotency key and never create a second delivery identity for the same artifact/destination pair.

## Authority Boundary
Telegram is communication and delivery only. It cannot modify project, layout, lighting, quantity, measurement, or design truth.

## Security
Bot token and destination credentials remain runtime secrets. They are never stored in project artifacts, Git, test fixtures, or logs.

## Acceptance
M21.20 deterministic mock delivery: 5/5 PASS.
