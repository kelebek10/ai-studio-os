# PAI-FORGE — Bridge Runtime v1 Prerequisites & Contract

Document ID: BRIDGE-RUNTIME-001
Version: 1.0
Status: CONTROLLED DESIGN BASELINE — NOT YET DEPLOYED, NOT YET RUNTIME-VERIFIED
Branch: phase-1-3-foundation
Owner: Human Project Owner
Parent: AI-COMMUNICATION-LOOP-v1.0 (COMM-001), TOOL-ACCESS-POLICY-v1.0 (TOOL-001)
Related: BRIDGE-TGA-CAW-001 (TGA/CAW acceptance criteria), COMM-BRIDGE-DESIGN-01
handoff (Issue #2, 5728126090), GPT verification P0/P1 findings (Issue #2, 5728137223)
Author: AGENT-CLAUDE-001 (per COMM-BRIDGE-IMPLEMENT-03)

## 1. Purpose

Close the five P0/P1 gaps GPT identified against `COMM-BRIDGE-DESIGN-01`
with concrete contract language, before any Bridge Runtime code is
deployed anywhere. This document does not deploy anything; it defines
what a correct deployment must satisfy.

## 2. P0-1 — Trigger authenticity / authority (closes GPT P0-1)

`issue_comment.created` alone is transport, not authority (per
`TOOL-ACCESS-POLICY-v1.0` §2: "Tool availability is not permission").

**Contract:** The Bridge's webhook listener MUST, before any dispatch:
1. Extract the envelope from the comment body.
2. Verify a signature over the exact envelope bytes using a secret/key
   registered only to `AGENT-GPT-001`'s producer identity (HMAC-SHA256
   minimum; see `bridge-runtime/trigger_auth.py::verify_signature`).
3. Reject if the GitHub comment author is not the registered Human
   Project Owner or GPT-operating account — signature check and
   author-identity check are both required, neither is sufficient
   alone (defense in depth: a compromised account still needs the
   signing secret, and a leaked secret still needs the right account).
4. Reject if repo/branch/policy_version/permission_version do not
   match the Bridge's current allow-list (TGA-03/04).
5. Reject if the envelope was already processed (TGA-06, trigger-layer
   idempotency key = `sha256(producer_id + task_id + correlation_id + envelope_hash)`).
Any failure at steps 2-5 → `BLOCKED / CONFLICT_LINEAGE_RESET_ATTEMPT`
or `BLOCKED / UNAUTHORIZED_TRIGGER` as appropriate, logged per TGA-08,
and **dispatch does not occur**.

## 3. P0-2 — Claude wake-up unproven (closes GPT P0-2)

**Contract:** "Claude API/Claude Code" is recorded here explicitly as
a **design option, not a verified capability**. No Result Handoff may
describe CAW-01..10 as PASS until:
(a) a real listener is deployed and reachable,
(b) the Bridge holds its own Claude API credentials (never Claude's),
(c) an end-to-end dispatch has been independently observed starting a
session with no human relaying the message, logged outside this chat.
Until then, every Bridge Runtime status report MUST carry
`CAW: UNVERIFIED / BLOCKED` verbatim — this contract makes that
non-optional, not a matter of phrasing choice per report.

## 4. P1-1 — Atomic 3-round DB enforcement (closes GPT P1-1)

A bare `CHECK(highest_round <= 3)` is insufficient under concurrent
writers (two dispatch attempts could both read `highest_round=2`
before either commits `3`). **Contract:** round advancement MUST use
a single atomic statement, not read-then-write:

```sql
UPDATE bridge.round_lineage
SET highest_round = $2, updated_at = now()
WHERE logical_problem_id = $1
  AND highest_round < $2
  AND $2 <= 3
RETURNING highest_round;
```

If the `UPDATE` returns zero rows, the caller MUST treat this as
`BLOCKED / ROUND_LIMIT_OR_STALE` — never fall back to a separate
SELECT+INSERT that could race. For a first-ever `logical_problem_id`
use `INSERT ... ON CONFLICT (logical_problem_id) DO UPDATE ... WHERE
bridge.round_lineage.highest_round < EXCLUDED.highest_round` with the
same `<= 3` guard, so a single statement handles both first-insert and
advance cases atomically.

## 5. P1-2 — Replay acceptance/consumption ordering (closes GPT P1-2)

GPT's concern: a UNIQUE constraint on `(task_id, correlation_id,
artifact_digest)` alone doesn't specify *when* a result is considered
"consumed" relative to concurrent submission, and doesn't address the
case of the same logical result resubmitted under a **different**
`task_id`.

**Contract:**
1. The idempotency key MUST be scoped to the invariant that actually
   defines "same result": `logical_problem_id + artifact_digest`, not
   `task_id + correlation_id + artifact_digest` as originally drafted
   in `COMM-BRIDGE-DESIGN-01` — a different `task_id` carrying the
   identical `logical_problem_id` and `artifact_digest` IS a replay,
   and the earlier design would have missed it. This is a correction
   to the earlier draft, made explicit here.
2. A result is "consumed" (eligible to progress `RESULT_SUBMITTED` →
   `GPT_REVIEW`) only after the INSERT into `bridge.result` commits
   successfully — an in-flight, uncommitted submission is not yet
   replay-protected and concurrent identical submissions race safely
   on the DB's own UNIQUE constraint (the loser gets a constraint
   violation, mapped to `BLOCKED / replay`, exactly as the earlier
   Bridge PoC's `ReplayGuard` already modeled at logic level).

## 6. P1-3 — Delegation scope canonicalization (closes GPT P1-3)

Free-text scope comparison is not reliable. **Contract:** `scope`
MUST be a canonical, sorted, deduplicated list of permission-model
tokens already defined in `AGENT-PERMISSION-MODEL-v1.0.md` (not
free text). A delegation's scope is valid only if it is a subset of
its parent task's scope using set containment, checked in application
code AND re-checked with a Postgres `<@` (array/jsonb containment)
constraint at the DB layer — defense in depth, matching TGA-01's
"neither alone is sufficient" pattern. If `AGENT-PERMISSION-MODEL-v1.0.md`
does not yet define a token vocabulary suitable for this, that is a
**prerequisite gap**, not something this document invents by itself.

## 7. P1-4 — Specialist-agent delegation capability (closes GPT P1-4)

**Contract, stated plainly:** No delegation runtime status may read
PASS until a specific, named, verifiable mechanism exists by which
Claude can bound and dispatch work to another agent under this
Bridge's control. As of this document, none exists in this
environment (confirmed capability gap, repeated across
`COMM-BRIDGE-IMPLEMENT-02` and `COMM-BRIDGE-IMPLEMENT-03` Result
Handoffs). Delegation-related tests remain `CAPABILITY GAP` until a
mechanism is named and independently confirmed reachable.

## 8. P1-5 — GitHub permission boundary (closes GPT P1-5)

**Contract:** "Read/comment-only" was a design recommendation, not a
statement of the current connector's actual granted scope. This
document does not claim to have verified Claude's current GitHub
token scope (that requires an action outside this chat — checking the
GitHub App/OAuth installation's granted permissions from the GitHub
organization settings, which Claude cannot read via the tools
available here). **This is recorded as an open verification item for
the Human Project Owner**, not resolved by this document.

## 9. Non-prod-only deployment boundary

Everything in this document and its accompanying scaffolding
(`bridge-runtime/`, `migrations/nonprod/015_bridge_runtime_schema.sql`)
targets a disposable non-production environment only, exactly like
the existing `migrations/nonprod/*` artifacts. No file here is a
production migration or deployment script. Deployment itself (running
the webhook listener somewhere reachable, applying the SQL to a real
Postgres) is explicitly **out of scope for this document and for
Claude's current capability** — it requires a human or CI action.

## 10. Status

`GO WITH CHANGES` at the contract-language level for the five P0/P1
items GPT raised — each has a concrete resolution above. `BLOCKED`
still applies to any claim of runtime verification: nothing in this
document has been deployed or executed against real infrastructure.
