# CHECKPOINT — 2026-09-16 — M15-A Human Authorization

**Branch:** `phase-1-3-foundation`  
**Status:** PAUSED / READY FOR USER CONTINUATION  
**Production mutation:** BLOCKED

## What was completed

1. Claude, Gemini and Copilot adversarial review results were reconciled.
2. Common security baseline was accepted without treating any AI verdict as project approval.
3. M15-A threat model was frozen.
4. Human Authorization Protocol baseline was frozen.
5. Passkey/WebAuthn was selected as the primary daily authorization direction.
6. Separate recovery credential was selected as the recovery direction; PUK-like high-entropy recovery code remains a candidate UX mechanism and is not an unrestricted master key.
7. Authorization payload baseline was frozen.
8. Authorization state machine was frozen.
9. Nonce, expiry, replay and revocation requirements were frozen.
10. AUTH-01..AUTH-10 minimum acceptance criteria were frozen.
11. ADV-01..ADV-20 adversarial test contract was frozen.
12. CURRENT-STATE.md was updated to v2.4.

## Pinned files

- `governance/M15-A-HUMAN-AUTHORIZATION-THREAT-MODEL-v1.0.md`
- `governance/M15-A-AUTHORIZATION-PROTOCOL-DESIGN-v1.0.md`
- `governance/M15-A-HUMAN-AUTHORIZATION-ADVERSARIAL-TEST-MATRIX-v1.0.md`
- `governance/CURRENT-STATE.md`

## Frozen rules

- Human approval is separate from GitHub PR approval.
- AI consensus is never human authority.
- Telegram is notification-only.
- NVIDIA is compute-only and cannot mutate Core.
- Agent, orchestrator and reviewer cannot create human authorization.
- `UNKNOWN`, `FAIL`, `TIMEOUT`, missing evidence and ambiguity are fail-closed to `BLOCKED`.
- Authorization is bound to task, correlation, commit, artifact and action.
- Nonce replay is rejected.
- Expired and revoked authorization is rejected.
- Recovery does not grant unrestricted production authority.
- Production migration, production SQL, data import, deployment promotion and infrastructure mutation remain blocked.

## Current M15-A state

**DESIGN:** PINNED  
**IMPLEMENTATION:** NOT STARTED  
**RUNTIME TESTS:** NOT STARTED  
**INDEPENDENT REVIEW OF IMPLEMENTATION:** NOT STARTED  
**M15-A:** BLOCKED / DESIGN-AND-TEST GATE

## Next step when user resumes

Do not write production code. First produce the M15-A implementation contract covering:

- component boundaries;
- identity model;
- authorization verification boundary;
- nonce generation/storage/consumption;
- expiry and trusted time;
- revocation;
- replay prevention;
- recovery and credential rotation;
- evidence schema;
- exact state-transition authority;
- non-production test harness.

Then implement only the minimum controlled non-production scaffolding and execute AUTH-01..AUTH-10 and ADV-01..ADV-20 with real evidence.
