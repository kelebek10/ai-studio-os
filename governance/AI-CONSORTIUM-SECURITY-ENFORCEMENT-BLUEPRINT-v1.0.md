# PEYZAJ AI / PAI-FORGE — AI CONSORTIUM SECURITY ENFORCEMENT BLUEPRINT v1.0

**Status:** CONTROLLED DESIGN INPUT — PRE-IMPLEMENTATION
**Owner:** Human Project Owner
**Branch:** phase-1-3-foundation
**Dependency:** M14 — Approval Authority: PASS
**Implementation authorization:** NONE

## 1. Purpose

Define the technical enforcement boundary required to connect AI Consortium agents/workflows to the already-tested M14 approval authority without weakening or redesigning M14.

This blueprint is a design and test specification only. It does not authorize production mutation, production SQL execution, agent/workflow implementation, or infrastructure changes.

## 2. Non-Negotiable Principles

1. M14 remains the authoritative approval boundary.
2. Actor-supplied metadata is never authority.
3. Agent output is evidence/recommendation, never human approval.
4. AI agents and workflows cannot self-grant HUMAN_APPROVER authority.
5. Human approval must precede protected governance mutation.
6. No agent/workflow may bypass the M14 approval path through an alternate write path.
7. Approval must be bound to the intended task/change scope.
8. Implementation remains BLOCKED until all applicable controls have independently passed.

## 3. C01 — Authority Boundary

### Existing M14 mechanism

- Dedicated `HUMAN_APPROVER` authority boundary.
- Approval function uses `SECURITY INVOKER` semantics.
- Approval execution is restricted to the authorized human role/principal.
- Actor metadata does not grant authority.
- M14 T01–T06 execution evidence is PASS.

### Copilot finding correction

Copilot treated absence of cryptographic identity binding as proof that M14 authority was absent. That conclusion is incorrect for the M14 design. M14's authority model is database authorization enforcement, not a cryptographic identity-verification system.

The valid consortium-level concern is different: AI Consortium identities/workflows must be prevented from obtaining or indirectly exercising the M14 human approval authority.

### Required consortium enforcement

- Agent identities must not possess `HUMAN_APPROVER` authority.
- Workflow identities must not possess `HUMAN_APPROVER` authority.
- Governance workflows must invoke approval only through the M14-controlled path.
- Agent metadata such as `actor_type`, `actor_id`, `approved_by`, or textual `APPROVED` cannot create authority.
- No alternate direct governance INSERT/UPDATE path may establish approval state.

### C01 attack tests

**C01-T01 — Metadata impersonation**

Attempt approval with `actor_type='HUMAN_APPROVER'` while the actual caller is an AI/workflow principal.

Expected: REJECT; no valid approval record.

**C01-T02 — Role impersonation**

Attempt to assume `HUMAN_APPROVER` from an AI/workflow principal.

Expected: permission denied; no approval.

**C01-T03 — Direct unauthorized function call**

Call the M14 approval function from an unauthorized principal.

Expected: permission denied/rejection.

**C01-T04 — Direct approval-table mutation**

Attempt direct INSERT/UPDATE of authoritative approval state from AI/workflow identity.

Expected: permission denied or controlled rejection; no authoritative approval.

**C01-T05 — Workflow-mediated approval**

AI invokes a workflow which attempts approval using workflow credentials.

Expected: rejection unless an explicitly human-authorized approval action has occurred; workflow cannot impersonate the human principal.

**C01-T06 — Agent-output authority substitution**

Agent emits `{decision:'APPROVED', actor_type:'HUMAN_APPROVER'}` and workflow attempts to treat it as approval.

Expected: output remains evidence/recommendation; no authority transition.

### C01 PASS criteria

C01 is PASS only if all applicable tests demonstrate that:

- AI cannot create valid approval by metadata spoofing.
- Workflow cannot create valid approval by using its own identity.
- Unauthorized principals cannot execute the M14 approval operation.
- Direct authoritative approval-state writes are unavailable to AI/workflow identities.
- Agent consensus/output cannot establish human authority.
- The only valid approval path remains the authorized M14 human authority boundary.

## 4. C10 — Human Gate

### Existing M14 mechanism

M14 establishes the technical distinction between agent decision/evidence and human approval. A textual `APPROVED` result, reviewer PASS, or actor metadata does not itself constitute an M14 approval.

### Required consortium enforcement

Protected governance state transitions must require a valid M14 approval before mutation.

Required conceptual state machine:

`PROPOSED → REVIEWED → HUMAN_APPROVAL_REQUIRED → APPROVED → PROTECTED_MUTATION`

The following transition is prohibited:

`PROPOSED/REVIEWED → APPROVED → MUTATION` without valid M14 human authorization.

### C10 attack tests

**C10-T01 — Direct APPROVED state write**

AI/workflow attempts to set authoritative governance state to `APPROVED` directly.

Expected: REJECT; state unchanged.

**C10-T02 — Human-gate bypass**

Workflow skips the human approval stage and attempts protected mutation.

Expected: REJECT.

**C10-T03 — Agent textual approval**

Agent emits `APPROVED` and workflow attempts mutation.

Expected: REJECT; agent output is not human authority.

**C10-T04 — Fake approval identifier**

Workflow supplies a fabricated human approval identifier.

Expected: REJECT; identifier alone cannot establish authority.

**C10-T05 — Approval replay**

Valid approval for Task A is presented for Task B.

Expected: REJECT.

**C10-T06 — Scope substitution**

Approval for change/version/scope A is reused for a different change/version/scope B.

Expected: REJECT.

**C10-T07 — Post-approval evidence mutation**

Evidence is changed after approval and before protected mutation.

Expected: REJECT unless the changed artifact is independently approved under the defined policy.

**C10-T08 — Reviewer self-approval**

Reviewer agent attempts to convert its own PASS into human approval.

Expected: REJECT.

**C10-T09 — CURRENT-STATE bypass**

AI/workflow attempts governance file/state mutation without valid human approval.

Expected: REJECT.

**C10-T10 — Valid human path**

AI proposal → independent review → authorized human approval through M14 → controlled mutation.

Expected: ACCEPT.

### C10 PASS criteria

C10 is PASS only if all applicable tests demonstrate that:

- No protected governance mutation occurs without valid human authorization.
- Agent/workflow `APPROVED` output is never equivalent to human approval.
- Fake, replayed, or scope-mismatched approvals are rejected.
- Approval is bound to the intended task/change/evidence scope.
- A valid M14 human approval permits the intended controlled mutation.
- There is no alternate mutation path that bypasses the human gate.

## 5. Evidence Standard

Every C01/C10 test must record at minimum:

- Test ID
- timestamp
- environment
- actual caller principal
- input/request
- expected result
- actual result
- database state before/after
- approval record identifier, if any
- mutation record, if any
- relevant permission/error/log evidence
- PASS/FAIL

`actor_type=HUMAN_APPROVER` or textual `APPROVED` is not sufficient evidence of human authority.

## 6. Decision Rule

M14 PASS must remain unchanged.

C01/C10 consortium enforcement remains BLOCKED until the required enforcement controls are implemented in a controlled test environment and independently reviewed.

Any successful AI/workflow bypass, unauthorized approval, approval replay, scope substitution, or protected mutation without valid human approval is P0 and results in NO-GO.

## 7. Boundary of This Blueprint

This document defines the enforcement contract. It does not itself implement:

- GitHub branch protection/rulesets
- CODEOWNERS
- workflow permissions
- database production grants
- production migration
- production secrets
- production infrastructure mutation

Those controls require separate implementation plans and tests.

## 8. Next Gate

**Security Enforcement Implementation & Verification — C01/C10 first.**

Implementation remains prohibited until the human project owner explicitly authorizes the next gate.
