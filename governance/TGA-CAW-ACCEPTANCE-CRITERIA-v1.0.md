# PAI-FORGE — TGA/CAW Acceptance Criteria v1.0

Document ID: BRIDGE-TGA-CAW-001
Version: 1.0
Status: CONTROLLED DESIGN BASELINE — NOT YET RUNTIME-VERIFIED
Branch: phase-1-3-foundation
Owner: Human Project Owner
Parent: AI-COMMUNICATION-LOOP-v1.0 (COMM-001), TOOL-ACCESS-POLICY-v1.0 (TOOL-001)
Author: AGENT-CLAUDE-001 (per COMM-BRIDGE-IMPLEMENT-03)
Reviewer: AGENT-GPT-001 (independent verification required before this
document may be cited as implementation-complete)

## 0. Why this document exists

`COMM-BRIDGE-IMPLEMENT-02` and `COMM-BRIDGE-DESIGN-01` referenced
`TGA-01..08` and `CAW-01..10` as if they were pre-existing acceptance
criteria. A repository code search (`TGA-01 OR CAW-01`) found **zero**
prior definition. This document is that missing definition, written
now, for the first time — it does not claim any of these criteria
have been met.

## 1. Scope

TGA = GPT Trigger Authenticity. CAW = Claude Automatic Wake-Up. Both
apply to the `Controlled Bridge Runtime` described in
`COMM-BRIDGE-DESIGN-01` (Issue #2, comment 5728126090) as revised by
GPT's P0/P1 findings (Issue #2, comment 5728137223).

For each criterion this document records:
- **Given/When/Then** — the exact behavior required
- **Evidence type required for PASS** — what a verifier must see
- **Executable today?** — whether this environment (a chat-based
  Claude session, no network egress, no DB connector, no deployed
  listener) can produce real evidence for it right now, or whether it
  categorically requires infrastructure that does not exist yet

Per `COMM-BRIDGE-IMPLEMENT-03` instruction: mock/simulation is not
PASS. Where "Executable today" is NO, the criterion's status is
`BLOCKED / CAPABILITY GAP`, not PASS, regardless of any logic-level
test that exists for a sub-part of it.

## 2. TGA — GPT Trigger Authenticity

**TGA-01 — Producer identity verified**
Given a task envelope arriving at the Bridge's trigger endpoint,
When the Bridge checks the envelope's signature against the
registered producer's public key/shared secret,
Then dispatch proceeds only if the signature is valid for the exact
payload bytes received.
Evidence required: real signed request against a real deployed
verification endpoint, with the raw request/response logged.
**Executable today: NO** (no deployed endpoint) — logic-level HMAC
verification function can be unit-tested (see §5), which is evidence
for the *algorithm*, not for TGA-01 itself.

**TGA-02 — Task envelope integrity**
Given a signed envelope, When any byte of the payload is altered
after signing, Then verification must fail.
Evidence required: same as TGA-01 (real endpoint) for the criterion;
unit-tested for the algorithm only.
**Executable today: NO** (criterion) / algorithm unit-testable.

**TGA-03 — Repo/branch match**
Given a validated envelope, When `envelope.branch` is compared to the
Bridge's configured controlled branch, Then dispatch is denied on any
mismatch.
Evidence required: real endpoint test with a wrong-branch payload.
**Executable today: NO** (criterion) / pure comparison logic
unit-testable.

**TGA-04 — Policy/permission version validity**
Given a validated envelope, When `policy_version`/`permission_version`
are checked against the Bridge's current allow-list, Then dispatch is
denied if either is absent from the allow-list.
Evidence required: real endpoint test with a stale version.
**Executable today: NO** (criterion) / allow-list lookup unit-testable.

**TGA-05 — Unauthorized producer rejected**
Given a well-formed envelope with an invalid or missing signature,
When submitted to the Bridge, Then the Bridge denies dispatch and
does not treat "well-formed" as sufficient (this directly closes
GPT's P0-1 finding: `issue_comment.created` alone is not authority).
Evidence required: real endpoint test with an unsigned/forged payload.
**Executable today: NO** (criterion) / same unit-tested algorithm as
TGA-01.

**TGA-06 — Trigger-layer replay rejected**
Given a previously accepted trigger event (identified by a
trigger-level idempotency key, distinct from the RESULT-level replay
key already covered by the earlier Bridge PoC), When the identical
event is resubmitted, Then the Bridge denies re-dispatch.
Evidence required: real endpoint, two identical requests, second
denied.
**Executable today: NO** (criterion) / dedup-set logic unit-testable.

**TGA-07 — Fail-closed on malformed envelope**
Given an envelope missing a required field or with an invalid type,
When submitted, Then the Bridge denies dispatch — never defaults or
partially proceeds.
Evidence required: real endpoint test with malformed payloads.
**Executable today: NO** (criterion) / schema validation
unit-testable (this is the same validator pattern as the earlier
Bridge PoC's `schema.py`, extended for the trigger envelope).

**TGA-08 — Attributable, append-only trigger audit**
Given any accept or deny decision, When it is recorded, Then the
record includes producer identity claim, envelope hash, decision,
reason, and timestamp, and cannot be altered after the fact.
Evidence required: real Postgres append-only table (reusing
`governance.reject_mutation()` pattern) with a real attempted
UPDATE/DELETE shown to fail.
**Executable today: NO** (needs real Postgres) / an in-memory
append-only audit function can be unit-tested for the *shape* of the
property, not the DB-enforced guarantee.

## 3. CAW — Claude Automatic Wake-Up

**CAW-01 — Trigger event received by listener**
Given a GitHub event on the scoped repo, When it matches the
listener's subscription, Then the listener receives it.
**Executable today: NO** — no deployed listener exists.

**CAW-02 — Listener applies TGA-01..08 before forwarding**
Given a received event, When the listener evaluates it, Then it only
forwards to the Bridge if all TGA checks pass.
**Executable today: NO** — depends on CAW-01.

**CAW-03 — Bridge dispatches a Claude session**
Given a forwarded, TGA-validated task, When the Bridge calls the
Claude API/Claude Code using the Bridge's own credentials, Then a new
Claude session is started for that task.
**Executable today: NO** — no Bridge deployment, no Bridge-held
Claude API credentials exist. This is the same "missing trigger"
capability gap identified in the very first analysis of this thread
and confirmed unresolved by GPT's own P0-2 finding.

**CAW-04 — Session starts without direct human message**
Given CAW-03, When the session begins, Then no human typed the
triggering message into this chat interface.
**Executable today: NO**, and note the structural point already
raised in the prior Result Handoff: this specific session cannot
self-certify this criterion even in principle, because any session
capable of writing this document was itself started by a message.
Only an external, independently observable dispatch log (outside
this chat) could ever serve as evidence here.

**CAW-05 — Claude reads task automatically**
Given CAW-04, When the session starts, Then the task is already in
context without further human relay.
**Executable today: NO** — depends on CAW-03/04.

**CAW-06 — Automatic ACK posted within timeout window**
Given CAW-05, When Claude acknowledges, Then the ACK is posted to
GitHub within the task's configured timeout with no human forwarding
the message.
**Executable today: NO** — depends on CAW-03/04/05.

**CAW-07 — Correlation/logical_problem_id match**
Given an ACK, When compared to the originating task envelope, Then
`task_id`, `correlation_id`, and `logical_problem_id` match exactly.
Evidence required for the full criterion: real ACK from a real
automatic dispatch (blocked, see CAW-03..06).
**Executable today for the matching algorithm only: YES** — pure
equality-check logic, unit-tested (§5). This is NOT evidence for
CAW-07 as a whole, only for the comparison function it depends on.

**CAW-08 — Timeout handling**
Given a dispatched task with no ACK within the timeout window, When
the timeout elapses, Then the Bridge marks `TIMEOUT` and does not
silently retry or proceed to `WORKING`.
Evidence required for the full criterion: real Bridge + real timer
against a real non-responding dispatch.
**Executable today for the state-transition algorithm only: YES** —
this is exactly what the earlier Bridge PoC's `acknowledge()` +
mock-callable-returns-False test already demonstrated at logic level
(TEST-12). Re-affirmed here, still not real-runtime evidence for
CAW-08 itself.

**CAW-09 — Unauthorized wake attempt rejected**
Given a forged/unauthenticated call attempting to start a Claude
session, When received by the invocation layer, Then it is rejected
before any session starts.
**Executable today: NO** — this depends on the real Claude
API/Claude Code invocation layer's own authentication, which is a
product-level mechanism outside this conversation's control and
cannot be tested from inside a chat session.

**CAW-10 — Restart continuity of wake/dispatch state**
Given a Bridge restart after a task was dispatched but before ACK,
When the Bridge comes back up, Then it recovers the correct pending
state from Postgres rather than re-dispatching blindly or losing the
task.
**Executable today: NO** — needs real Postgres + real Bridge process.

## 4. Summary table

| ID | Executable today (real runtime) | Algorithm unit-testable now |
|---|---|---|
| TGA-01 | NO | YES |
| TGA-02 | NO | YES |
| TGA-03 | NO | YES |
| TGA-04 | NO | YES |
| TGA-05 | NO | YES |
| TGA-06 | NO | YES |
| TGA-07 | NO | YES |
| TGA-08 | NO | partial (shape only, not DB guarantee) |
| CAW-01 | NO | NO |
| CAW-02 | NO | NO |
| CAW-03 | NO | NO |
| CAW-04 | NO | NO (structurally unprovable from inside a session) |
| CAW-05 | NO | NO |
| CAW-06 | NO | NO |
| CAW-07 | NO | YES (matching function only) |
| CAW-08 | NO | YES (state-transition function only) |
| CAW-09 | NO | NO |
| CAW-10 | NO | NO |

**No row in this table is PASS.** Algorithm-level unit tests are
supporting evidence for a future real-runtime PASS, not a substitute
for one. This distinction must be preserved by any verifier reading
future Result Handoffs against this contract.

## 5. Where algorithm-level tests live

`bridge-runtime/trigger_auth.py` + `tests/bridge-runtime/test_trigger_auth.py`
(this same commit) implement and test, for real, in this sandbox:
signature verification (TGA-01/02/05), branch match (TGA-03),
version allow-list (TGA-04), trigger replay dedup (TGA-06), envelope
schema fail-closed validation (TGA-07), append-only audit log shape
(TGA-08 partial), correlation matching (CAW-07), and timeout state
transition (CAW-08). See that test file's real output for exact
PASS/FAIL per function — never cited as criterion-level PASS.

## 6. Acceptance

This document itself is a governance artifact, not a runtime PASS.
It becomes useful the moment TGA-01..08/CAW-01..10 need to be
verified against a real deployed Bridge — until then it is the
canonical reference so future tasks stop re-inventing these IDs
ad hoc.
