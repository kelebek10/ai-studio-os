# PAI-FORGE — M15-A Human Authorization Protocol Design v1.0

**Status:** CONTROLLED DESIGN BASELINE — NOT IMPLEMENTED  
**Phase:** M15-A  
**Branch:** `phase-1-3-foundation`  
**Owner:** Human Project Owner  
**Production mutation:** BLOCKED

## 1. Design Decision

PAI-FORGE will use a two-layer human authorization model:

1. **Primary daily authorization:** Passkey / WebAuthn.
2. **Recovery:** separate recovery credential, with PUK-like high-entropy recovery code as a candidate UX mechanism, subject to deterministic security controls.

A separate signing key remains an implementation alternative for recovery/break-glass control and must be evaluated before final implementation.

The system must remain independent of any single AI provider.

## 2. Security Boundary

Human authorization is outside the authority of:

- Supervisor
- Orchestrator
- Control
- Architect
- Researcher
- Implementer
- Reviewer
- Evidence agent
- n8n
- Telegram
- NVIDIA adapter
- GitHub workflow automation

Those components may prepare, validate or route evidence, but none can manufacture human authority.

**Control clarification:** Control is a deterministic policy-enforcement component, not an AI agent. Its authorization decisions MUST NOT depend on LLM output, model confidence, AI consensus, prompt interpretation or mutable natural-language instructions. The detailed contract is pinned in `governance/M15-A-CONTROL-DETERMINISM-CONTRACT-v1.0.md`.

## 3. Daily Authorization Flow

```text
Human Project Owner
       |
       v
  Authorization UI
       |
       v
 Passkey / WebAuthn
       |
       v
Fresh challenge / nonce
       |
       v
Human-readable action summary + authorization payload
       |
       v
Deterministic verification gate
       |
       v
Authorized operation
```

The authorization UI MUST present, before the human confirmation step, the security-relevant action and binding context in human-readable form. At minimum this includes action, target, task/correlation identity, commit identity, artifact digest or digest summary where applicable, expiry, and affected resource/diff summary where applicable.

A cryptographic signature without an understandable action presentation is insufficient for a critical authorization. Any mismatch between the displayed authorization summary and the executed action MUST produce BLOCKED.

The user should not need to remember or type a PAI-FORGE master password for every authorization. Device biometric/PIN may unlock the passkey locally.

## 4. Recovery Flow Baseline

```text
Normal passkey unavailable
        |
        v
Controlled recovery authentication
        |
        v
Recovery credential verification
        |
        v
Mandatory recovery delay / notification window
        |
        v
Revoke affected old credential(s)
        |
        v
Register new passkey
        |
        v
Create recovery evidence
        |
        v
Return to normal authorization
```

Recovery must not directly grant unrestricted production mutation authority.

Recovery credentials must be high-entropy, single-use or deterministically rotated after use, replay-protected and auditable. A recovery event must trigger a controlled notification through a separate communication channel. Telegram may serve notification only; it is not the approval authority.

Final implementation must define the recovery delay, cancellation semantics, second-factor requirements, credential rotation and atomicity before M15-A READY.

Recovery UX details belong to the Settings layer and are intentionally not implemented in M15-A.

## 5. Authorization Payload

Minimum fields:

```text
authorization_id
task_id
correlation_id
commit_sha
artifact_digest
action
nonce
issued_at
expires_at
human_identity
authorization_method
```

The payload must be integrity protected and verified before authorization is accepted.

## 6. Nonce

Requirements:

- generated for each authorization attempt;
- unpredictable/high entropy;
- unique within the authorization trust domain;
- stored/referenced sufficiently to detect reuse;
- consumed atomically;
- never reused as a general static secret.

Nonce reuse MUST produce BLOCKED.

## 7. Expiry

Every authorization has an explicit `expires_at`.

Rules:

- expired authorization cannot be used;
- expiry cannot be extended by modifying stored authorization data;
- clock handling must use a defined trusted time source;
- boundary-condition tests must exist;
- expired state is terminal unless a new authorization is issued.

## 8. Revocation

Authorization/credential revocation must be deterministic.

Revoked authorization cannot be reactivated.

Recovery must revoke affected old credentials before or as part of new credential enrollment according to the final atomic recovery design.

Revocation state must be auditable.

## 9. Replay Protection

Replay is prevented through the combined use of:

- unique authorization ID;
- fresh nonce;
- explicit expiry;
- atomic consumption state;
- task/scope binding;
- commit binding;
- artifact digest binding;
- action binding.

A previously consumed authorization is not a valid authorization for any later operation.

## 10. Scope Binding

Authorization is valid only for the exact security scope it was issued for.

At minimum:

`task_id + correlation_id + commit_sha + artifact_digest + action`

Any mismatch produces BLOCKED.

Rollback is an action and therefore requires its own valid authorization scope.

## 11. State Machine

```text
ISSUED
  |
  v
ACTIVE
  +----> USED
  +----> EXPIRED
  +----> REVOKED
```

Terminal states:

- USED
- EXPIRED
- REVOKED

Terminal states cannot return to ACTIVE.

No agent or orchestrator can perform the state transition that represents human authorization consumption on behalf of the human.

## 12. Authority Separation

| Component | May request evidence | May validate | May create human authorization | May consume human authorization |
|---|---:|---:|---:|---:|
| Human Project Owner | Yes | Yes | **Yes** | Yes |
| Supervisor | Yes | Yes | No | No |
| Orchestrator | Yes | Yes | No | No |
| Control | Yes | Yes | No | No |
| Architect | Yes | Yes | No | No |
| Researcher | Yes | Yes | No | No |
| Implementer | Yes | Yes | No | No |
| Reviewer | Yes | Yes | No | No |
| Evidence | Yes | Yes | No | No |
| Telegram | Notification only | No | No | No |
| NVIDIA adapter | Compute only | No | No | No |

Final implementation must enforce this separation technically, not only in documentation.

## 13. Independent Verification

Before an authorization can open a protected operation, the verification layer must independently check:

1. human identity;
2. authorization integrity;
3. nonce state;
4. expiry;
5. revocation state;
6. task/correlation binding;
7. commit binding;
8. artifact digest binding;
9. action binding;
10. required evidence and governance checks;
11. displayed action summary binding where a human-readable confirmation is required.

Failure of any required check => BLOCKED.

## 14. Human Approval vs GitHub Approval

GitHub PR review/approval may be a repository governance requirement, but it is not by itself the PAI-FORGE cryptographic Human Authorization Protocol.

The final design may combine GitHub review controls with the authorization protocol, but neither layer may silently substitute for the other.

## 15. Human Approval vs Telegram

Telegram is notification/communication only.

A Telegram message, button, callback or account identity is not sufficient as the sole Human Authorization proof.

Telegram may later trigger a secure authorization UX, but the authorization must terminate in the independent human authorization mechanism.

## 16. Human Approval vs AI Consensus

AI consensus is evidence/analysis, not authority.

No combination of:

- Claude;
- Gemini;
- Copilot;
- Kimi;
- Supervisor;
- Orchestrator;
- Reviewer;

can produce a human authorization.

## 17. Production Boundary

Until M15-A is proven:

- no production migration;
- no production SQL execution;
- no production data import;
- no production deployment promotion;
- no unrestricted Oracle mutation;
- no Telegram approval channel;
- no NVIDIA Core mutation path.

## 18. Implementation Readiness Gate

M15-A implementation cannot start beyond controlled non-production scaffolding until the following are frozen:

- payload schema;
- nonce policy;
- expiry policy;
- revocation policy;
- replay policy;
- recovery policy;
- identity model;
- verification boundary;
- state transition authority;
- evidence schema;
- deterministic Control contract;
- human-readable action presentation contract;
- adversarial test contract.

The adversarial test contract is pinned separately in:

`governance/M15-A-HUMAN-AUTHORIZATION-ADVERSARIAL-TEST-MATRIX-v1.0.md`

## 19. Exit Condition

M15-A becomes READY only after:

1. deterministic implementation exists in non-production;
2. AUTH-01..AUTH-10 pass with runtime evidence;
3. ADV-01..ADV-20 produce the required outcomes;
4. P0-1 through P0-4 are closed with evidence;
5. evidence integrity is verified;
6. independent review passes;
7. no unresolved P0/P1 authority or integrity issue remains;
8. Human Project Owner explicitly accepts the gate.
