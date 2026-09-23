# PAI-FORGE — M16.10 TELEGRAM GATEWAY CONTRACT v1.0

**Status:** IMPLEMENTED / UNIT-TESTED / E2E VERIFIED — M16.10

## Purpose

Telegram is an untrusted human-facing transport. The gateway converts an allowed Telegram command into a bounded PAI-FORGE task intent. It never grants authority and never writes Core.

## Controls

1. Only registered Telegram chat IDs are accepted.
2. Empty input is rejected.
3. Commands are allowlisted.
4. /approve is rejected at ingress and can only be handled through the existing Human Gate + M14 authority path.
5. Created tasks use the orchestrator role but do not grant approval authority.
6. Every task carries source commit, evidence requirement, prohibited actions and logical problem lineage.
7. Telegram remains transport/interface; GitHub governance remains source of truth.
8. Bot token and provider credentials never enter task payloads.

## E2E target

Telegram → n8n Gateway → Security/Governance → GPT-5.6 Luna Orchestrator → Model Adapter → Worker → Review → Evidence → Human Gate/Security → n8n → Telegram.

## E2E Verification — M16.10

Real n8n/Telegram evidence:
- workflow: `PAI-FORGE - M16.10 Telegram Gateway E2E`
- workflow ID: `PAIM1610GATE01`
- activation: verified active
- Telegram E2E execution: #33
- execution status: `success`
- Telegram response: `Operational acknowledgement received.`
- legacy workflow `PAIOLLAMATEST01` was disabled before M16.10 activation.
- `appendAttribution=false` remains enabled for the M16.10 Telegram response nodes.

This verifies the controlled Telegram Gateway E2E boundary. The gateway remains transport-only and does not grant approval authority.
