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
- Control agent
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
Authorization payload
(task + commit + artifact + action)
       |
       v
Deterministic verification gate
       |
       v
Authorized operation
```

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
10. required evidence and governance checks.

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
- adversarial test contract.

The adversarial test contract is pinned separately in:

`governance/M15-A-HUMAN-AUTHORIZATION-ADVERSARIAL-TEST-MATRIX-v1.0.md`

## 19. Exit Condition

M15-A becomes READY only after:

1. deterministic implementation exists in non-production;
2. AUTH-01..AUTH-10 pass with runtime evidence;
3. ADV-01..ADV-20 produce the required outcomes;
4. evidence integrity is verified;
5. independent review passes;
6. no unresolved P0/P1 authority or integrity issue remains;
7. Human Project Owner explicitly accepts the gate.
