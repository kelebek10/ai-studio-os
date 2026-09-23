# PEYZAJ AI — Telegram Operations Architecture v1.0

## Purpose
Telegram is the human operations surface for PAI-FORGE.
It reduces the need for continuous screen monitoring.

## Flow
User -> Telegram -> n8n Command Gateway -> PAI-FORGE Orchestrator
Orchestrator <-> SECURITY_INTELLIGENCE_DIRECTOR
Director <-> SECURITY / INTELLIGENCE / REDTEAM
Orchestrator <-> AI Bridge -> Claude / Gemini / Copilot
Core/Agents -> Event Bus -> Alert Engine -> Telegram

## Boundaries
Telegram never writes Core directly.
n8n orchestrates transport only.
Director can block, warn and report; it cannot approve Core.
Secrets remain in n8n credentials or a secret store.
Provider responses remain untrusted until validation.

## Initial commands
/status /missions /report /alerts /ask /pause /resume /logs

Approval commands remain behind an explicit human gate.

## Rollout
1. Create Telegram bot.
2. Store bot token only in n8n credentials.
3. Import command/alert workflows.
4. Restrict allowed Telegram chat IDs.
5. Test status, warning and critical alert paths.
6. Verify audit events.
7. Activate only after evidence passes.
