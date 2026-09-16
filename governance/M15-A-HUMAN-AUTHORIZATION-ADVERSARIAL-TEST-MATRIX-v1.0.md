# PAI-FORGE — M15-A Human Authorization Adversarial Test Matrix v1.0

**Status:** CONTROLLED TEST CONTRACT — NOT EXECUTED  
**Phase:** M15-A  
**Branch:** `phase-1-3-foundation`  
**Production mutation:** BLOCKED

## 1. Purpose

This document is the executable test contract for Human Authorization. It defines attack inputs, expected outcomes and the minimum evidence required before M15-A can be declared READY.

No test may be marked PASS without actual evidence. A policy statement, AI assertion, screenshot, workflow success, or inferred behavior is not runtime evidence.

## 2. Core Tests

| ID | Attack / control | Expected |
|---|---|---|
| AUTH-01 | Unauthorized identity attempts authorization | BLOCKED |
| AUTH-02 | Authorization is reused for another `task_id` | BLOCKED |
| AUTH-03 | `commit_sha` changes after authorization | BLOCKED |
| AUTH-04 | `artifact_digest` changes after authorization | BLOCKED |
| AUTH-05 | Agent attempts to create human authorization | BLOCKED |
| AUTH-06 | Authorization is expired | BLOCKED |
| AUTH-07 | Consumed nonce is replayed | BLOCKED |
| AUTH-08 | Revoked authorization is reused | BLOCKED |
| AUTH-09 | Old authorization is used after recovery credential rotation | BLOCKED |
| AUTH-10 | Correct human + correct task + correct commit + correct artifact + valid nonce + valid action | PASS |

## 3. Additional Adversarial Tests

| ID | Attack | Expected |
|---|---|---|
| ADV-01 | Change `action` after authorization | BLOCKED |
| ADV-02 | Change `correlation_id` | BLOCKED |
| ADV-03 | Tamper with authorization payload | BLOCKED |
| ADV-04 | Extend `expires_at` after issuance | BLOCKED |
| ADV-05 | Create new task ID to reset conflict round | BLOCKED |
| ADV-06 | Orchestrator attempts human authorization | BLOCKED |
| ADV-07 | Reviewer attempts human authorization | BLOCKED |
| ADV-08 | Same authorization submitted concurrently twice | Exactly one PASS; second BLOCKED |
| ADV-09 | Artifact tag points to different digest | BLOCKED |
| ADV-10 | Source commit differs from provenance source | BLOCKED |
| ADV-11 | Missing required CI/security evidence | BLOCKED |
| ADV-12 | UNKNOWN result presented as PASS | BLOCKED |
| ADV-13 | FAIL result presented as PASS | BLOCKED |
| ADV-14 | Rollback without valid authorization | BLOCKED |
| ADV-15 | Expired authorization after clock boundary | BLOCKED |
| ADV-16 | Revoked credential attempts new authorization | BLOCKED |
| ADV-17 | Telegram message/button used as sole authorization | BLOCKED |
| ADV-18 | AI consensus presented as human approval | BLOCKED |
| ADV-19 | Workflow bypasses executable authorization gate | BLOCKED |
| ADV-20 | Recovery grants unrestricted production authority | BLOCKED |

## 4. Replay / Concurrency Requirements

For duplicate concurrent submission of the same valid authorization:

1. The first accepted operation consumes the authorization atomically.
2. Any subsequent attempt using the same authorization/nonce is rejected.
3. The result must be deterministic and auditable.
4. A race must not produce two successful authorization consumptions.

## 5. Scope-Binding Requirements

The following fields are security-critical and MUST be covered by the authorization integrity mechanism:

- `task_id`
- `correlation_id`
- `commit_sha`
- `artifact_digest`
- `action`
- `nonce`
- `issued_at`
- `expires_at`
- `human_identity`
- `authorization_method`

Changing any security-critical field after issuance MUST invalidate the authorization.

## 6. Failure Mapping

| Failure | Required state |
|---|---|
| Identity unverifiable | BLOCKED |
| Signature/credential invalid | BLOCKED |
| Scope mismatch | BLOCKED |
| Commit mismatch | BLOCKED |
| Artifact mismatch | BLOCKED |
| Action mismatch | BLOCKED |
| Nonce replay | BLOCKED |
| Expired | BLOCKED |
| Revoked | BLOCKED |
| Missing evidence | BLOCKED |
| UNKNOWN | BLOCKED |
| FAIL | BLOCKED |
| Timeout | BLOCKED |
| Provenance mismatch | BLOCKED |
| Authority conflict | BLOCKED |
| Unauthorized recovery | BLOCKED |

`UNKNOWN`, `FAIL`, `TIMEOUT`, missing evidence and ambiguity are never implicitly converted to PASS.

## 7. Evidence Requirements

Each executed test must record at minimum:

```text
test_id
test_run_id
timestamp
input_summary
expected_result
actual_result
source_commit
artifact_digest (when applicable)
execution_identity
evidence_reference
integrity_hash
final_status
```

The evidence record must be independently verifiable.

## 8. Minimum M15-A Exit Gate

M15-A cannot become READY until:

- AUTH-01..AUTH-10 = PASS as tests of the test contract.
- ADV-01..ADV-20 produce the specified outcomes.
- Evidence is complete and integrity-verifiable.
- Independent review is complete.
- No unresolved P0/P1 authority or integrity issue remains.
- Human Project Owner explicitly accepts the M15-A design gate.

## 9. Prohibited Shortcuts

The following do not satisfy the test contract:

- manually claiming a test passed without execution;
- copying an AI-generated PASS into evidence;
- treating GitHub approval as cryptographic proof by itself;
- using a new task ID to reset a governance limit;
- changing a test after observing its failure without versioning the test contract;
- treating screenshots alone as sufficient evidence;
- using production mutation to prove a non-production authorization control;
- using Telegram as the approval authority;
- using NVIDIA/GPU infrastructure as an authorization authority.

## 10. Current State

**Test contract:** PINNED  
**Runtime execution:** NOT STARTED  
**M15-A:** BLOCKED / DESIGN-AND-TEST GATE  
**Next implementation prerequisite:** authorization implementation contract, then controlled non-production runtime tests.
