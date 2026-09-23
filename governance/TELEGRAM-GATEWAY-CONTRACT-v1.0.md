# PAI-FORGE — M16.10 TELEGRAM GATEWAY CONTRACT v1.0

**Status:** IMPLEMENTED / UNIT-TESTED — E2E NOT YET VERIFIED

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

## Current boundary

The gateway ingress contract is implemented and unit-tested. Full E2E remains blocked until the n8n workflow can invoke the registered PAI-FORGE orchestrator/runtime endpoint and return its controlled result without bypassing Security/Governance.
