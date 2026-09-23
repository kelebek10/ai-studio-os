# PAI-FORGE — MASTER RESUME CHECKPOINT
**Document ID:** PAI-FORGE-RESUME-001  
**Version:** 1.5  
**Status:** CONTROLLED / RESUME SOURCE OF TRUTH  
**Branch:** `phase-1-3-foundation`  
**Owner:** Human Project Owner  
**Last updated:** 2026-09-23

## 1. PURPOSE
A new chat MUST read this checkpoint and relevant governance documents, then verify GitHub branch/HEAD and runtime state before changing anything. Do not reconstruct project state from conversation alone.

## 2. AUTHORITY
`HUMAN PROJECT OWNER → SECURITY / GOVERNANCE CONTROL → GPT-5.6 LUNA ORCHESTRATOR → AI MODELS → WORKERS → SPECIALIST AGENTS`
Security/Governance is independent and monitors all layers, including the orchestrator. No AI/agent can create human authority or self-approve protected actions.

## 3. OPERATING RULE
PAI-FORGE is a task network, not a free-conversation network. Every AI/agent communication must be task-bound, scoped and necessary. Free/open-ended AI-to-AI conversation is prohibited. Runtime enforcement is required.

## 4. WORKFLOW
`TASK → CONTROL CHECK → ROUTE → EXECUTE → VERIFY → EVIDENCE → HANDOFF → GPT VERIFICATION → NEXT CONTROLLED ACTION`

## 5. THREE-ROUND RULE
Only a real unresolved problem opens a conflict loop. Maximum three rounds. Unresolved after Round 3 becomes `BLOCKED` and proceeds upward/HUMAN_GATE when required. Changing task/provider/agent/workflow/channel/chat cannot reset the same `logical_problem_id`. Security violations are blocked immediately.

## 6. TELEGRAM
Telegram is the human-facing operational interface:
`HUMAN PROJECT OWNER ↔ TELEGRAM ↔ SECURITY/GATEWAY ↔ GPT-5.6 LUNA`
It is transport, not source of truth.

## 7. VERIFIED TELEGRAM BASELINE
`Telegram → n8n → Ollama/Qwen3 1.7B → n8n → Telegram`
Workflow: `PAI-FORGE - Ollama Telegram Test`, ID `PAIOLLAMATEST01`, verified execution #29: `Test alındı. Qwen3 aktif.`, footer removed, success. Protected baseline; do not unnecessarily modify.

Backup: `/tmp/PAIOLLAMATEST01.final-backup.json`  
SHA-256: `67e2c19730c6d133bc9eb96ea1bf19e63cb8fbc434c90aef606ac4cb9910a1bd`

## 8. CURRENT RUNTIME
Repository: `kelebek10/ai-studio-os`  
Branch: `phase-1-3-foundation`  
Lifecycle: `VALIDATED → ROUTING → EXECUTING → REVIEW → EVIDENCE → COMPLETED`  
Special states: `BLOCKED`, `HUMAN_GATE`  
AI cannot output `APPROVED`.

### M16.1 — VERIFIED
TaskEnvelope lifecycle, Human Gate declaration, lineage, three-round hard stop and APPROVED rejection.
Evidence: `M16.1 RUNTIME HARNESS: PASS`

### M16.2 — VERIFIED
Deterministic router only accepts VALIDATED tasks, rejects unknown targets, CORE/HUMAN/SUPERVISOR routing and double routing.
Evidence: `M16.2 ROUTER HARNESS: PASS`
Boundary PASS only; not E2E.

### M16.3 — VERIFIED
Provider-neutral ModelAdapter requires ROUTING, registered provider, identity preservation, non-empty response, model identity match and rejects model APPROVED output.
Evidence: `M16.3 ADAPTER HARNESS: PASS`
Boundary PASS only; not live Qwen3 E2E.

### M16.5 — VERIFIED

Bounded Researcher Worker is implemented and tested.

Controls:
- accepts only `researcher` role;
- starts only from `ROUTING`;
- requires declared evidence;
- transitions task to `EXECUTING` before model execution;
- uses the provider-neutral ModelAdapter;
- preserves task/correlation/scope identity;
- rejects authority output (`APPROVED`);
- free-chat is prohibited by the task contract.

Real device evidence:
- unit harness: `M16.5 UNIT HARNESS: PASS`
- live Ollama/Qwen3 Researcher call: PASS
- returned model: `qwen3:1.7b`
- returned marker: `PAI-FORGE M16.5 RESEARCHER LIVE PASS`
- `M16.5 LIVE RESEARCHER HARNESS: PASS`

ModelAdapter was corrected so model execution is permitted from the active worker state `EXECUTING` as well as `ROUTING`. This matches the lifecycle ownership boundary: routing assigns; worker claims execution; adapter invokes the untrusted provider.

Current verified branch HEAD:
`fd04faf11f8fd25ae62d60b938f4f01705eb480d`

### M16.6 — VERIFIED

Bounded independent Reviewer Worker is implemented and tested.

Controls:
- accepts only `reviewer` role;
- starts only from `ROUTING`;
- requires declared evidence;
- requires a source task ID and non-empty research content;
- transitions task to `EXECUTING`;
- reviews supplied research through the provider-neutral ModelAdapter;
- preserves source task identity;
- rejects `APPROVED` as authority output;
- prohibits free-chat/self-approval through the task contract.

Real device evidence:
- unit harness: `M16.6 UNIT HARNESS: PASS`
- negative controls: role, evidence, source content, unrouted state and approval output all blocked
- live Ollama/Qwen3 Reviewer call: PASS
- returned model: `qwen3:1.7b`
- source task: `m16.5-live-researcher`
- returned marker: `PAI-FORGE M16.6 REVIEWER LIVE PASS`
- reviewer produced a concrete unsupported-claim and missing-evidence analysis
- `M16.6 LIVE REVIEWER HARNESS: PASS`

Current verified branch HEAD:
`6ca66ba284470ee71f6d5ee5c6c46de259ec8b1e`

### M16.4 — VERIFIED
Live Ollama provider for `qwen3:1.7b` is implemented without modifying the protected Telegram workflow.
Provider controls:
- registered model required;
- task/correlation identity preserved;
- 90s timeout;
- Qwen3 thinking disabled for worker calls;
- provider failure fails closed;
- model output remains untrusted and is passed through ModelAdapter validation.

Real device evidence:
- Ollama health found `qwen3:1.7b`: PASS
- live ModelAdapter → Ollama → Qwen3 call: PASS
- returned model: `qwen3:1.7b`
- returned response contained requested test marker: PASS
- `M16.4 LIVE QWEN3 HARNESS: PASS`

Note: an initial 30s timeout was insufficient for the live local model. This was observed as a real timeout, then corrected to 90s before final PASS.

Current verified branch HEAD:
`9c2e78666db98d9458d9aa01e6896595582ac6c2`

## 9. SECURITY
Workers/AI cannot modify governance to remove blocks, grant permissions, self-assert human approval, bypass provenance/evidence, perform protected production operations without authorization, or access tools outside registered scope. Control Agent and M14 approval-authority controls remain protected.

## 10. GOVERNANCE REFERENCES
Before continuing, read as applicable:
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

## 11. M16 DIRECTION
Target:
`Telegram → n8n Gateway → Security/Governance → GPT-5.6 Luna Orchestrator → AI Model Adapter → Worker → Specialist Agents → Review → Evidence → Orchestrator → Security/Gateway → n8n → Telegram`
Qwen3 is a worker/model adapter, not authority.

Completed:
1. Task Contract runtime schema
2. Orchestrator router
3. Provider-neutral Model Adapter
4. Live Qwen3 provider integration
5. Researcher Worker — VERIFIED
6. Reviewer Worker — VERIFIED

Next:
5. Researcher Worker — VERIFIED
6. Reviewer Worker — VERIFIED
7. Evidence Worker
8. Human Gate
9. Telegram E2E
10. negative/security tests
11. evidence package

## 12. RESUME
1. State active model: GPT-5.6 Luna.
2. Read this checkpoint and relevant governance.
3. Verify branch/HEAD/runtime.
4. Compare against last checkpoint.
5. Continue from exactly the last verified stage.
6. Never claim PASS without fresh real evidence.

## 13. STOP RULE
If state is missing, contradictory, stale or unverified:
`STOP → INVESTIGATE → EVIDENCE → RESUME`

## 14. CHANGE CONTROL
Material changes require version update, explicit change description, Git commit and preserved evidence/history.
