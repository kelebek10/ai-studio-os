# PAI-FORGE — EVIDENCE WORKER CONTRACT v1.0

**Document ID:** EVIDENCE-001  
**Version:** 1.0  
**Status:** CONTROLLED / M16.7 VERIFIED  
**Branch:** `phase-1-3-foundation`  
**Owner:** Human Project Owner

## 1. Purpose

Evidence Worker establishes deterministic provenance and integrity for a material result handoff. It does not decide whether the underlying claim is scientifically true and does not grant authority.

## 2. Role

- Agent role: `evidence`
- Task class: `evidence.verify`
- Boundary: post-review evidence/integrity layer
- Authority: none

## 3. Entry Conditions

The task MUST:
- belong to agent role `evidence`;
- be in `REVIEW` state;
- contain required evidence declarations;
- identify the source task;
- identify producer and producer status;
- contain a non-empty artifact;
- contain at least one evidence reference.

Producer status `APPROVED` is forbidden.

## 4. Deterministic Processing

Evidence Worker:
1. computes SHA-256 of the exact artifact;
2. optionally compares it with an expected digest;
3. canonicalizes provenance metadata using stable key ordering;
4. computes a SHA-256 evidence digest;
5. preserves task ID, correlation ID, scope and source commit;
6. transitions the task from `REVIEW` to `EVIDENCE`.

Same inputs MUST produce the same artifact and evidence digests.

## 5. Required Evidence Record

- task_id
- correlation_id
- scope
- source_commit
- source_task_id
- producer
- producer_status
- artifact_digest
- evidence_digest
- evidence_refs

## 6. Prohibited Actions

Evidence Worker MUST NOT:
- assert `APPROVED`;
- create human authority;
- change governance;
- alter provenance to make a result pass;
- infer scientific truth from a digest;
- bypass GPT verification;
- perform protected production mutation;
- use free/open-ended AI-to-AI conversation.

## 7. Failure-Closed Conditions

The worker MUST block/fail on:
- wrong role;
- wrong lifecycle state;
- missing identity/provenance;
- empty artifact;
- missing references;
- approval semantics;
- digest mismatch.

## 8. Acceptance Evidence

Real device:
- `M16.7 UNIT HARNESS: PASS`
- deterministic replay: PASS
- negative controls: PASS
- live Qwen3 Reviewer output accepted as evidence input: PASS
- `M16.7 LIVE QWEN3 EVIDENCE HARNESS: PASS`

Live evidence digest:
`ae4a9be7b91ee5935ed46ed20536087702d3963fe297165828bf601af620965b`

## 9. Authority Boundary

Evidence Worker produces an evidence record. It does not produce project authority, human approval or final acceptance. GPT verification and any required Human Gate remain mandatory.

