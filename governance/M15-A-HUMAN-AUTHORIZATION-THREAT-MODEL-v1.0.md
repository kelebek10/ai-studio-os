# PAI-FORGE — M15-A Human Authorization Protocol Threat Model v1.0

**Status:** CONTROLLED DESIGN BASELINE — NOT IMPLEMENTED  
**Phase:** M15-A  
**Owner:** Human Project Owner  
**Authority:** Human Project Owner remains final authority  
**Production mutation:** BLOCKED  
**Branch:** `phase-1-3-foundation`

## 1. Purpose

M15-A defines the minimum security model for proving that a production-affecting authorization was issued by the authorized human, for the exact intended scope, against the exact source and artifact, and has not expired, been revoked, or replayed.

Human authorization is a distinct security boundary. Agent output, reviewer consensus, GitHub metadata, Telegram messages, workflow completion, or artifact metadata MUST NOT be interpreted as human approval by themselves.

## 2. Threat Actors

| Actor | Target | Threat level |
|---|---|---|
| Compromised AI Agent | authority escalation / approval creation | High |
| Compromised Orchestrator | Human Gate bypass | High |
| Compromised Reviewer | false PASS / manipulated evidence | High |
| Compromised GitHub account/token | PR, approval, merge or workflow abuse | High |
| Workflow attacker | disable or bypass governance checks | High |
| Artifact attacker | substitute unapproved image | High |
| Evidence manipulator | FAIL/UNKNOWN to PASS or historical rewrite | High |
| Replay attacker | reuse old valid authorization/artifact | High |
| Prompt-injection attacker | manipulate agent behavior | High |
| Credential attacker | impersonate authorized human | High |

## 3. Trust Assumptions

The system may rely only on these bounded assumptions:

1. The Human Project Owner has a unique, verifiable identity.
2. The human authorization credential is protected and is not assumed to be permanently uncompromisable.
3. Repository governance controls are active and reviewable.
4. Authorization is bound to an explicit operation scope.
5. Source and artifact digests are independently verifiable.
6. CI results are deterministically testable.
7. Agents cannot create human authorization.
8. Orchestrator cannot merge, deploy, or approve as a human.
9. Telegram is notification-only and is not an authority channel.
10. Oracle must accept only explicitly authorized and verified artifacts.

No trust is placed in a single AI provider merely because it is a different model/provider.

## 4. Security Goals

**G1 — Human identity:** authorization must be attributable to the authorized human through a cryptographically verifiable mechanism.

**G2 — Scope binding:** authorization must bind at minimum to `task_id`, `correlation_id`, source `commit_sha`, `artifact_digest`, and `action`.

**G3 — Integrity:** a source, artifact, or action change invalidates the authorization.

**G4 — Single-use / replay resistance:** a consumed authorization cannot be reused; nonce and expiry must be enforced.

**G5 — Agent separation:** no AI agent, orchestrator, reviewer, workflow or automated consensus may create or self-assign human authorization.

**G6 — Fail-closed:** missing, ambiguous, expired, revoked, mismatched or unverifiable authorization produces `BLOCKED`.

**G7 — Auditability:** every authorization decision has durable evidence sufficient for independent verification.

**G8 — Recovery safety:** recovery credentials can restore human access without becoming an unrestricted production bypass.

**G9 — Rollback parity:** rollback requires the same authorization integrity controls as forward promotion.

## 5. Failure Conditions

The following are mandatory `BLOCKED` conditions:

- Human identity cannot be verified.
- Authorization signature/credential cannot be verified.
- Required authorization scope is incomplete.
- `commit_sha` does not match.
- `artifact_digest` does not match.
- `action` does not match.
- Authorization belongs to another task/correlation context.
- Authorization is expired.
- Authorization is revoked.
- Nonce has already been consumed.
- Source-to-artifact provenance cannot be verified.
- Required CI/security evidence is missing.
- Reviewer evidence is missing where required.
- Evidence integrity is broken.
- Conflict-round limit is exceeded.
- Orchestrator/agent/reviewer attempts to create human authorization.
- Workflow attempts to bypass the authorization gate.
- Rollback lacks the required authorization chain.
- Authorization timestamp/nonce cannot be validated.
- GitHub and runtime authorization state disagree.

`UNKNOWN` MUST NOT become `PASS`.

## 6. Minimum Acceptance Criteria

All ten criteria must PASS before M15-A can be marked READY:

- **AUTH-01 — Human Identity:** authorized human identity is deterministically verifiable.
- **AUTH-02 — Scope Binding:** authorization binds to task, correlation, commit, artifact and action.
- **AUTH-03 — Integrity:** changing source or artifact invalidates authorization.
- **AUTH-04 — Agent Denial:** agents, orchestrator and reviewer cannot create human authorization.
- **AUTH-05 — Replay Denial:** an old authorization cannot authorize a different or repeated operation.
- **AUTH-06 — Fail Closed:** incomplete or suspicious authorization produces BLOCKED.
- **AUTH-07 — Evidence:** authorization produces independently verifiable evidence.
- **AUTH-08 — Workflow Enforcement:** the gate is enforced by executable controls, not documentation alone.
- **AUTH-09 — Rollback Binding:** rollback follows the same authorization boundary.
- **AUTH-10 — Adversarial Runtime Test:** all defined attack cases are rejected or accepted exactly as specified.

## 7. Protocol Decision Baseline

### Primary: Passkey / WebAuthn

Daily human authorization should use a passkey backed by the user's device security (biometric or device PIN). The private key remains on the device. A fresh challenge/nonce is generated for each authorization.

### Recovery: separate recovery credential

Recovery is separate from normal authorization. A PUK-like recovery code is acceptable as a recovery mechanism only if it is high-entropy, securely stored, auditable, rate-limited, scoped, and consumed/rotated under deterministic rules. It must not become an unrestricted production master key.

A separate signing key remains an alternative recovery/control mechanism to be evaluated during implementation design.

## 8. Authorization Payload Baseline

The implementation contract must include at minimum:

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

The authorization payload itself must be integrity-protected. Any modification invalidates the authorization.

## 9. Authorization State Machine

```text
ISSUED
  |
  v
ACTIVE
  +----> USED
  +----> EXPIRED
  +----> REVOKED
```

Rules:

- A nonce is unique per authorization.
- An expired authorization cannot be reactivated.
- A revoked authorization cannot be reactivated.
- A used authorization cannot be reused.
- Recovery invalidates the affected prior authorization credentials according to the recovery policy.
- No agent may transition authorization to `ACTIVE` or `USED`.
- No orchestrator may transition authorization to `ACTIVE` or `USED`.

## 10. Explicit Non-Trust Boundaries

The following do NOT constitute human authorization:

- AI response saying `APPROVED`.
- Reviewer consensus.
- Orchestrator completion.
- GitHub workflow success.
- PR metadata alone.
- Telegram message/button alone.
- Commit message alone.
- Artifact tag alone.
- Docker image existence alone.
- Automated metadata generation.

## 11. Recovery Principles

If the user's phone is lost, broken, replaced, or the normal authentication path is unavailable:

1. Recovery must authenticate the human independently.
2. Existing authorization credentials must be revocable.
3. A new passkey must be registered explicitly.
4. Old credentials must not silently remain trusted.
5. Recovery must create auditable evidence.
6. Recovery must not bypass source/artifact/task scope controls.
7. Recovery must not directly grant unrestricted production mutation authority.

Detailed settings, recovery UX, code format, storage, rotation and emergency procedures are intentionally deferred to the implementation design and settings layer.

## 12. Stop Conditions

M15-A remains BLOCKED if any AUTH-01..AUTH-10 is not proven by deterministic runtime evidence and independent review.

No production mutation, production migration, live deployment, Telegram approval channel, or NVIDIA Core mutation path may be enabled while M15-A is BLOCKED.
