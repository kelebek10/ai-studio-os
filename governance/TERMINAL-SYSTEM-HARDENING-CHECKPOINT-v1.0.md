# PEYZAJ AI — Terminal System Hardening & Resume Checkpoint v1.0

**Status:** CONTROLLED PROJECT MEMORY / MANDATORY OPERATING RULES
**Branch:** `phase-1-3-foundation`
**Repository:** `kelebek10/ai-studio-os`
**Purpose:** Prevent runtime drift, accidental file loss, repeated manual repair loops, and context loss while PEYZAJ AI automation is being built.

## 1. Why this checkpoint exists

The M15 implementation exposed an operational weakness: the Control Agent runtime source was being edited directly on the server and then copied into Docker images. This created competing host/container/image states and caused repeated restore/rebuild cycles. PEYZAJ AI must not continue with this operating model.

The immediate objective is to harden the terminal/runtime system first. **No new M15 implementation stage is authorized until this foundation is stable.**

## 2. Binding source-of-truth rule

GitHub on `phase-1-3-foundation` is the canonical source. The runtime server is not the source of truth.

Mandatory chain:

`GitHub commit SHA → controlled Docker build → immutable image digest → container runtime → read-only verification → checkpoint`

A runtime file never becomes authoritative merely because it exists on the server.

## 3. Forbidden operating practices

For governed Control Agent source, do not:

- edit source inside a running container;
- use `printf >>` or ad-hoc SSH append as normal development;
- manually restore/copy source without a Git checkpoint;
- treat mutable tags such as `latest` as immutable release identifiers;
- mount mutable host source into the governed runtime;
- grant the Control Agent write access to governed source/governance files;
- change production state merely to make a test pass;
- claim PASS from a harness when governed runtime evidence is absent;
- proceed after a failed or ambiguous checkpoint.

## 4. Immutable runtime principle

The Control Agent image must be reproducible from a known Git commit and identified by an image digest. Runtime source is disposable.

Target properties:

- no source bind mounts;
- no Docker socket;
- read-only root filesystem where compatible;
- only explicitly required temporary writable paths;
- least-privilege database account;
- no production mutation authority;
- healthcheck enabled;
- image digest recorded in checkpoint.

## 5. Drift detection

Every controlled runtime checkpoint records at minimum:

- Git commit SHA;
- image digest;
- container ID;
- relevant source-file SHA-256 values;
- runtime health state;
- test/evidence status;
- blockers, if any.

If source, image, or runtime identity cannot be reconciled: **DRIFT_DETECTED / BLOCKED**.

Do not repair drift by guessing. Return to the last known-good checkpoint or rebuild from canonical Git source.

## 6. Read-only diagnostic rule

Failure investigation starts with read-only commands only. Permitted observations include container status, restart count, exit code, Docker error, entrypoint/command, image ID/digest, container ID, file existence/hash, read-only content inspection, logs, Docker configuration, and health/process state.

No stop/start/rebuild/recreate/edit/delete command is permitted during diagnosis unless explicitly authorized as a controlled recovery step.

## 7. One-command mobile terminal protocol

Because the project is operated heavily from a mobile terminal:

1. Give exactly one command.
2. State expected output.
3. State the stop condition.
4. Wait for the actual result.
5. Interpret it before issuing the next command.

If output is unexpected, **STOP**. Do not improvise a repair command.

## 8. Mandatory stop conditions

Stop immediately when:

- output differs materially from expectation;
- container enters a restart loop;
- Python syntax/import error appears;
- image digest is unknown or unexpectedly changes;
- source hash differs from checkpoint;
- runtime source cannot be traced to a Git commit;
- database privileges are broader than expected;
- a prohibited mutation succeeds;
- required evidence is missing/ambiguous;
- reviewer/evidence component is unavailable;
- authority is unclear;
- test evidence comes only from a mock/harness;
- a proposed fix requires bypassing source-of-truth or approval controls.

FAIL, UNKNOWN, TIMEOUT, missing evidence, integrity mismatch, authority conflict, scope ambiguity, or unavailable independent verification are fail-closed states.

## 9. Checkpoint rule

A milestone is not complete merely because implementation appears to work. A checkpoint requires:

`source identity + build identity + runtime identity + health + evidence + test result`

Only after reconciliation may the project move forward.

## 10. Current M15 state at interruption

**M15 Stage 1: BLOCKED / INCOMPLETE.**

Real runtime evidence:

- **O1:** PASS.
- **O4:** PASS. `CREATE TABLE` was denied; application table count remained `0`; mode remained `READ_ONLY`.
- **O2:** not yet validated against governed runtime.
- **O3:** not yet validated against governed runtime.
- **O5:** not yet validated against governed runtime.

The isolated `stage1_tests.py` harness does **not** count toward Stage-1 completion.

## 11. Runtime state at interruption

The host `observation.py` was temporarily modified while attempting to implement the Stage-1 observation contract. Host syntax compilation passed, but the running Docker container initially contained the previous image copy. After an image rebuild/recreate, `paiforge-control-agent` entered a restart loop.

**Current rule: do not mutate `observation.py` or repeatedly rebuild the container until the restart-loop cause has been diagnosed read-only.**

Immediate diagnostic targets:

- container status;
- restart count;
- exit code/error;
- logs/traceback;
- image identity/digest;
- entrypoint/command;
- container-side `observation.py` presence and SHA-256;
- container-side syntax/import state.

## 12. Previously verified baseline

Before the attempted Stage-1 modification, the restored `observation.py` baseline SHA-256 was:

`a45d69460b8e19d6f7d01ab2a8bb1e39fcb9d14fd2943c44f00f1f5873754363`

This is an identity record, not authorization for blind restoration. Recovery must first reconcile runtime state and then use canonical GitHub source.

## 13. Existing governance decisions that remain valid

- Main branch remains untouched.
- Work remains on `phase-1-3-foundation`.
- Control Agent is read-only operational supervision.
- No raw LLM access to the database.
- Production mutation remains prohibited until separately authorized.
- Human Project Owner remains final approval authority.
- Agent consensus never equals human approval.
- M14 governance must not be weakened to solve M15 runtime problems.
- Evidence and provenance remain mandatory.

## 14. Required hardening sequence

This is a dependency chain; do not skip ahead:

1. Diagnose current runtime read-only.
2. Establish known-good recovery point.
3. Establish canonical Control Agent source in GitHub.
4. Establish reproducible Docker build from that source.
5. Record immutable image digest.
6. Deploy disposable runtime from that exact image.
7. Verify source/image/runtime hashes.
8. Verify health and least privilege.
9. Create hardening checkpoint.
10. Resume M15 Stage 1 and execute O1–O5 against the real governed runtime.
11. Record evidence in GitHub.
12. Continue to later M15 stages only after the gate passes.

## 15. What must not happen next

Do not continue adding lines to the current server `observation.py`, attempt blind restore, repeatedly rebuild without diagnosis, mark Stage 1 complete, fabricate O2/O3/O5 evidence, or advance to later M15 stages merely to maintain momentum.

## 16. Resume instruction for future chats

When a new PEYZAJ AI chat starts, first read this checkpoint and the Terminal Runtime Control Standard before giving commands.

Use this resume instruction:

> **PEYZAJ AI — terminal sistemini sağlamlaştırma checkpoint'ini oku. Önce mevcut runtime'ı salt okunur teşhis et; GitHub'ı source of truth yapmadan M15'e devam etme.**

Preserve the one-command protocol and do not ask the user to repeat the history contained here.

## 17. Hardening completion definition

The terminal system is hardened only when:

- GitHub is canonical source;
- runtime source is reproducible from a commit;
- immutable image identity is recorded;
- container has no mutable source mount;
- runtime/source drift is detectable;
- health and privilege checks are reproducible;
- rollback to a recorded image/checkpoint is possible;
- failed deployment cannot silently become source of truth;
- workflow can be operated safely from a mobile terminal one command at a time.

Until then: **HARDENING / BLOCKED-FORWARD-PROGRESS**.
