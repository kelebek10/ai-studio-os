# PAI-FORGE — MASTER RESUME CHECKPOINT

**Document ID:** PAI-FORGE-RESUME-001  
**Version:** 1.1  
**Status:** CONTROLLED / RESUME SOURCE OF TRUTH  
**Branch:** `phase-1-3-foundation`  
**Owner:** Human Project Owner  
**Last updated:** 2026-09-23

## 1. PURPOSE

This document exists so a new ChatGPT session can resume PAI-FORGE without treating the project as new.

A new chat MUST first read this checkpoint and the referenced controlled governance documents, then verify the current GitHub branch/commit and runtime state before changing anything.

Do not reconstruct project state from conversational memory alone.

## 2. AUTHORITY HIERARCHY

`HUMAN PROJECT OWNER → SECURITY / GOVERNANCE CONTROL → GPT-5.6 LUNA ORCHESTRATOR / CHIEF ARCHITECT → AI MODELS → WORKERS → SPECIALIST AGENTS`

Important distinction:

- Human Project Owner is the final authority.
- Security/Governance is an independent enforcement boundary and monitors all layers, including the orchestrator.
- GPT-5.6 Luna is the project director, chief architect and orchestration/verification coordinator.
- Other AI models execute assigned roles.
- Specialist agents execute bounded tasks.
- No AI or agent can create human authority or self-approve protected actions.

## 3. CORE OPERATING RULE

PAI-FORGE is a **task network, not a free-conversation network**.

Free AI-to-AI conversation is prohibited.

Every AI/agent communication must be:
- tied to a valid task;
- within assigned scope;
- necessary for execution, verification, evidence, security, handoff or bounded conflict resolution.

No social, open-ended, unrelated or curiosity-driven AI conversation is permitted.

The runtime must enforce this rather than relying only on prompts.

## 4. NORMAL WORKFLOW

`TASK → CONTROL CHECK → ROUTE → EXECUTE → VERIFY → EVIDENCE → HANDOFF → GPT VERIFICATION → NEXT CONTROLLED ACTION`

Agents work first and communicate only what is required to complete or control the task.

## 5. GLOBAL THREE-ROUND RULE

The three-round rule applies to the entire AI/agent hierarchy.

It covers:
- AI ↔ AI;
- worker ↔ worker;
- specialist agent ↔ specialist agent;
- reviewer ↔ implementer;
- researcher ↔ evidence/reviewer;
- team ↔ team;
- orchestration-level substantive disagreements.

Normal acknowledgements, progress events, evidence delivery and result handoff do not count as conflict rounds.

Only a real unresolved problem opens a conflict loop.

Maximum:
- Round 1
- Round 2
- Round 3

If unresolved after Round 3:

`BLOCKED → upper-layer report → GPT-5.6 Luna assessment → HUMAN GATE when required → Human Project Owner`

Round 4 is forbidden.

Changing task ID, agent, AI provider, workflow, branch, channel or chat cannot reset the same `logical_problem_id`.

Security violations do not enter the three-round discussion. They are blocked immediately.

## 6. HUMAN / TELEGRAM CHANNEL

Telegram is the human-facing operational channel.

`HUMAN PROJECT OWNER ↔ TELEGRAM ↔ SECURITY/GATEWAY ↔ GPT-5.6 LUNA`

Telegram is transport/interface, not the project source of truth.

Durable task state, governance, evidence, decisions and checkpoints belong in the controlled project repository/evidence system.

## 7. CURRENT VERIFIED TELEGRAM BASELINE

The following integration is already proven and must be treated as a protected baseline:

`Telegram → n8n → Ollama/Qwen3 1.7B → n8n → Telegram`

Workflow:
- Name: `PAI-FORGE - Ollama Telegram Test`
- ID: `PAIOLLAMATEST01`
- Active: true
- Telegram bot: `PeyzajAIOpsBot`
- Verified execution #29 returned exactly: `Test alındı. Qwen3 aktif.`
- n8n attribution footer was removed.
- Execution status: success.
- This working path must not be unnecessarily modified while orchestration is built.

Backup:
- `/tmp/PAIOLLAMATEST01.final-backup.json`
- SHA-256: `67e2c19730c6d133bc9eb96ea1bf19e63cb8fbc434c90aef606ac4cb9910a1bd`

## 8. CURRENT RUNTIME BASELINE

Repository:
`kelebek10/ai-studio-os`

Active branch:
`phase-1-3-foundation`

Existing runtime foundation:
- Python Agent Runner
- Control Agent
- PostgreSQL
- Redis
- n8n

M15/M16 runtime Task Contract lifecycle:
`VALIDATED → ROUTING → EXECUTING → REVIEW → EVIDENCE → COMPLETED`

Special states:
- `BLOCKED`
- `HUMAN_GATE`

AI cannot output `APPROVED`.

### M16.1 — VERIFIED

The communication runtime TaskEnvelope now enforces:
- deterministic lifecycle transitions;
- explicit Human Gate declaration;
- logical problem / parent task lineage fields;
- three-round conflict hard stop;
- rejection of `APPROVED`.

Real device harness evidence:
`M16.1 RUNTIME HARNESS: PASS`

### M16.2 — VERIFIED

The deterministic `OrchestratorRouter` now:
- routes only `VALIDATED` tasks;
- rejects unknown/unavailable targets;
- rejects routing to `CORE`, `HUMAN`, or `SUPERVISOR`;
- cannot route an already-routed task again.

Real device harness evidence:
`M16.2 ROUTER HARNESS: PASS`

Current branch HEAD:
`4636c259d913e10be6db70e10ef340b2be663a08`

M16.2 is a **routing-boundary PASS**, not an end-to-end orchestration PASS.

## 9. SECURITY MODEL

Security/Governance is independent from implementation workers.

Workers/AI cannot:
- modify governance to remove their own block;
- grant themselves permissions;
- self-assert human approval;
- bypass provenance/evidence requirements;
- directly perform protected production operations without authorization;
- access tools outside their registered permission scope.

Read-only Control Agent and M14 approval-authority controls remain protected.

## 10. EXISTING GOVERNANCE DOCUMENTS

Before continuing work, read as applicable:

- `governance/AI-OPERATING-MODEL-v1.0.md`
- `governance/AI-COMMUNICATION-LOOP-v1.0.md`
- `governance/AI-CONSORTIUM-SECURITY-ENFORCEMENT-BLUEPRINT-v1.0.md`
- `governance/AI-CONSORTIUM-SECURITY-GOVERNANCE-M14-MINIMUM-CONTROLS-v1.0.md`
- `governance/AGENT-GOVERNANCE-ARCHITECTURE-v1.0.md`
- `governance/AGENT-PERMISSION-MODEL-v1.0.md`
- `governance/AGENT-REGISTRY-v1.0.md`
- `governance/TASK-CONTRACT-v1.0.md`
- `governance/AI-RESULT-HANDOFF-VERIFICATION-GATE-v1.0.md`
- `governance/AI-WORKER-PROFILES.md`
- `governance/AI-ROLE-MATRIX.md`
- `governance/CHECKPOINT-2026-09-15-M15-AGENT-RUNTIME.md`

## 11. CURRENT DEVELOPMENT DIRECTION — M16

Target chain:

`Telegram → n8n Gateway → Security/Governance → GPT-5.6 Luna Orchestrator → AI Model Adapter → Worker → Specialist Agents → Review → Evidence → Orchestrator → Security/Gateway → n8n → Telegram`

Qwen3 is a worker/model adapter, not the authority or decision center.

Completed:
1. Task Contract runtime schema
2. Orchestrator router

Next:
3. Model Adapter / Qwen3
4. Researcher worker
5. Reviewer worker
6. Evidence worker
7. Human Gate
8. Telegram E2E
9. negative/security tests
10. evidence package

Do not skip governance or evidence to accelerate implementation.

## 12. RESUME PROCEDURE FOR EVERY NEW CHAT

1. State the active model: GPT-5.6 Luna.
2. Read this checkpoint.
3. Read the relevant governance documents.
4. Verify current GitHub branch and HEAD.
5. Verify current runtime state.
6. Compare the current state with the last recorded checkpoint.
7. Identify exactly the last completed stage.
8. Continue from that stage.
9. Do not repeat completed work unless a verification gap requires it.
10. Do not claim PASS without fresh real evidence.

## 13. CURRENT STOP / QUALITY RULE

If state is missing, contradictory, stale or unverified:

`STOP → INVESTIGATE → EVIDENCE → RESUME`

Never guess the project state.

## 14. CHANGE CONTROL

This checkpoint itself is controlled project state.

Material changes require:
- version update;
- explicit change description;
- Git commit;
- preservation of prior evidence/history.
