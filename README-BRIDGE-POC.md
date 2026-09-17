# PAI-FORGE Communication Bridge — PoC (Issue #4 follow-up analysis task)

## What this is
A minimal, real, locally-tested implementation of the **control-plane
logic** for a GPT↔Claude task/result bridge: schema validation, round
limiting (max 3), replay protection, fail-closed gating, and a
deterministic state machine (TASK_CREATED → ... → VERIFIED/BLOCKED/
HUMAN_ACTION_REQUIRED/TIMEOUT).

## What this is NOT
This PoC does **not** implement an automatic, always-on listener that
wakes a Claude session when GPT posts to GitHub. That component does
not exist in the current toolset (see the prior analysis message in
this thread). Anywhere a "GPT" or "worker ACK" is needed, tests use an
explicit **MOCK callable** — clearly labeled in the EVIDENCE column of
the test output. No network calls, no secrets, no live GitHub polling
happen inside `bridge/` or `tests/`.

## Files
- `bridge/schema.py` — TASK/RESULT required-field schemas + validation
- `bridge/round_control.py` — max-3-round enforcement, keyed by
  `logical_problem_id` (not reset by new `task_id`)
- `bridge/replay_protection.py` — duplicate/replay detection keyed by
  `(task_id, correlation_id, artifact_digest)`
- `bridge/bridge.py` — orchestrator: `create_task`, `dispatch_task`,
  `acknowledge`, `submit_result`, `gpt_review` — all fail-closed
- `tests/test_bridge_poc.py` — TEST-01..TEST-15, executed for real
  (see `evidence_run_output.txt` for raw output, 15/15 PASS)

## Mocked components (explicit)
- Claude ACK / worker response — mocked callable (`worker_ack`)
- "GPT result retrieval" — modeled as a reachability check only; an
  actual GPT-side GitHub read is not performed by this code
- Timeout — simulated via a callable returning `False`, not a real
  wall-clock timer

## Known limitations / gaps
1. **No automatic wake-up mechanism.** GPT→Claude dispatch still
   requires a human (or an external scheduler/webhook calling the
   Claude API) to start a session — this PoC does not, and cannot
   from inside a chat session, change that.
2. Round-limit and replay state are **in-memory only** in this PoC
   (`RoundController`, `ReplayGuard`) — a real deployment needs this
   persisted (e.g. in the GitHub issue/comment history itself, or a
   small datastore), otherwise a new process restart resets state.
3. `gpt_review`'s "authority" is just a function return value — it is
   not wired to any real human-approval record. TEST-14 demonstrates
   this explicitly: the bridge's own verdict is not sufficient
   authority by design; an external governance gate must own that.
4. No GitHub Actions automation was added in this PoC (per "gereksiz
   yeni altyapı kurma" — avoided until confirmed needed).

## Status
Implementation of the control-logic layer: **PASS** (real, executed,
evidenced). Full end-to-end GPT↔Claude automatic bridge: **UNVERIFIED
/ BLOCKED** on the missing trigger component identified in the prior
analysis message.
