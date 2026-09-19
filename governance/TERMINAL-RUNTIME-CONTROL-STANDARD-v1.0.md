# PEYZAJ AI — Terminal Runtime Control & Immutable Checkpoint Standard v1.0

**Status:** CONTROLLED GOVERNANCE BASELINE  
**Branch:** `phase-1-3-foundation`  
**Owner:** Human Project Owner  
**Scope:** PEYZAJ AI / PAI-FORGE automation runtime, Control Agent and related Docker execution environment

## 1. Purpose

This document establishes the permanent operating discipline for terminal-based development and runtime management. The objective is to prevent file loss, uncontrolled overwrites, runtime/source drift, accidental mutation, repeated manual recovery, and loss of project continuity.

This standard is established **before further milestone execution**. Stabilizing the system is a prerequisite to continuing M15.

## 2. Source-of-Truth Principle

GitHub is the canonical source of controlled code and governance artifacts.

The SSH/host runtime directory is **not** the source of truth.

The running container is disposable runtime state and must never become the authoritative copy of source code.

Canonical chain:

`GitHub commit -> controlled build -> immutable Docker image -> container runtime -> verified checkpoint`

## 3. Immutable Build Principle

A runtime release must be identifiable by both:

- Git commit SHA
- Docker image digest (`sha256:...`)

Mutable tags such as `latest` must not be treated as release identity.

A container may be recreated from the exact image digest without editing source inside the container.

## 4. No In-Place Source Editing

The following practices are prohibited for controlled project code:

- `printf >> file` source modification
- ad-hoc `sed`/`awk` mutation of governed source
- manual source restoration over SSH
- editing source inside a running container
- copying an unverified host file into a runtime container
- treating a working container filesystem as a backup

Terminal commands may inspect, test, hash, build, deploy and verify. Source changes must originate from the controlled GitHub workflow.

## 5. Container Runtime Rules

Control Agent and governed automation containers should, where technically compatible, use:

- read-only root filesystem
- no host source-code mounts
- no Docker socket
- least-privilege database credentials
- no production mutation capability
- disposable container instances
- health checks

Writable storage, if required, must be explicitly scoped to temporary runtime needs and must not contain canonical source.

## 6. Drift Detection

Every controlled runtime checkpoint must record at minimum:

- Git commit SHA
- image digest
- container ID
- expected source file SHA256 values
- runtime-observed source file SHA256 values where applicable
- health status
- test status
- timestamp

Any mismatch is `DRIFT_DETECTED` and therefore `BLOCKED` until independently investigated.

No automatic reconciliation may silently overwrite evidence.

## 7. Checkpoint Principle

A checkpoint is a verified state, not a note saying that work was probably completed.

A valid checkpoint requires reproducible evidence for the exact source, image and runtime state.

Milestone progression must not rely on an unverified checkpoint.

## 8. Fail-Closed Rule

The following conditions stop progression:

- missing source identity
- missing image digest
- source/image mismatch
- runtime/source hash mismatch
- unexpected restart loop
- unexpected exit code
- health check failure
- test failure
- unknown state
- missing evidence
- authority ambiguity
- uncontrolled file mutation

The correct response is `BLOCKED`, not an assumption or workaround.

## 9. Recovery Rule

When runtime state becomes corrupted or ambiguous:

1. Stop making source changes in the runtime directory.
2. Preserve read-only diagnostic evidence.
3. Identify the last verified Git commit.
4. Identify the last verified image digest.
5. Recreate runtime from the verified immutable source/image.
6. Re-run validation.
7. Create a new checkpoint only after verification.

Manual file-by-file restoration is not an accepted recovery method.

## 10. Terminal Operating Discipline

For mobile/SSH operation:

- one command at a time
- wait for the result
- no chained mutation commands during diagnosis
- expected output defined before execution
- explicit stop condition for every diagnostic step
- no destructive command during diagnosis

Read-only diagnosis precedes any mutation.

## 11. Control-Agent Boundary

`control.py` remains the stable runtime health entrypoint unless a separately approved change is made.

`observation.py` must not be modified ad hoc during runtime troubleshooting.

Stage-1 observation implementation must eventually be introduced from canonical GitHub source and validated through an immutable build.

## 12. Current Incident / Checkpoint

At the time of this baseline, M15 Stage 1 is **NOT COMPLETE**.

Verified evidence before the current runtime incident:

- O1 real Control Agent observation: **PASS**
- O4 real mutation denial: **PASS**
- O2: not yet validly executed against the real observation contract
- O3: not yet validly executed against the real observation contract
- O5: not yet validly executed against the real observation contract

A later attempt modified the host `observation.py` directly and rebuilt the Control Agent. The resulting container entered a restart loop. The root cause has not yet been conclusively established.

The last known controlled baseline for `observation.py` before the ad-hoc modification had SHA256:

`a45d69460b8e19d6f7d01ab2a8bb1e39fcb9d14fd2943c44f00f1f5873754363`

The same hash had previously been verified inside the Control Agent image.

## 13. Immediate Rule

Do **not** continue M15 Stage 1 implementation until the terminal/runtime control baseline is stabilized and the current restart-loop state has been diagnosed read-only.

The next work must begin with runtime inventory and evidence preservation, followed by creation of a canonical GitHub source structure.

## 14. Continuity Reminder for Future Sessions

When this document is re-read, restore the following context:

- Project: PEYZAJ AI / PAI-FORGE
- Repository: `kelebek10/ai-studio-os`
- Branch: `phase-1-3-foundation`
- Main branch must remain untouched.
- GitHub is source of truth.
- Docker images are immutable by digest.
- Containers are disposable runtime.
- Runtime source editing is prohibited.
- Every milestone requires an evidence-backed checkpoint.
- M15 Stage 1 is blocked pending controlled runtime stabilization and valid O1–O5 execution.
- Do not declare M15 complete based on harness-only tests.
- Resume from the last verified checkpoint, not from assumptions.

## 15. Quality Gate

Before any future milestone progression, verify:

1. canonical source exists in GitHub;
2. source commit is identifiable;
3. image digest is identifiable;
4. runtime is recreated from the verified image;
5. runtime/source drift check passes;
6. health check passes;
7. required tests pass;
8. evidence is recorded;
9. human gate is respected where required.

**No milestone completion may bypass this gate.**
