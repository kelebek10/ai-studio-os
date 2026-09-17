# PAI-FORGE — M15-A Control Determinism Contract v1.0

**Status:** CONTROLLED DESIGN BASELINE — P0 SECURITY REQUIREMENT
**Phase:** M15-A
**Branch:** `phase-1-3-foundation`
**Owner:** Human Project Owner
**Production mutation:** BLOCKED

## 1. Purpose

This contract establishes the Control boundary as a deterministic security component. Control is the enforcement point between AI/orchestration activity and protected PAI-FORGE operations.

The Control component is **not an AI agent** and must not depend on LLM output, probabilistic classification, prompt interpretation, semantic judgment, or provider-specific behavior to make an authorization or mutation decision.

## 2. Core Rule

> **AI may propose. Control may verify. Only deterministic policy evaluation may authorize progression.**

No AI output can independently cause:

- `PASS`;
- authorization acceptance;
- protected Core mutation;
- production promotion;
- human-approval state transition.

`UNKNOWN`, missing, malformed, conflicting, stale or unverifiable input MUST NOT be converted to `PASS`.

## 3. Deterministic Input Contract

Control accepts only typed, schema-validated inputs. At minimum:

- task contract;
- authority context;
- governance/policy version;
- evidence references and integrity metadata;
- task lineage/conflict-round metadata;
- authorization record where required;
- source commit identity;
- artifact digest where required;
- requested action;
- current protected-resource state.

Untrusted natural-language content is data, not policy.

PR descriptions, issue text, commit messages, external research, AI-generated prose and model responses cannot modify Control policy, authority, scope or permissions.

## 4. Decision Function

Conceptually:

`decision = F(canonical_input, pinned_policy, protected_state)`

For identical canonical inputs, pinned policy and protected state, the result MUST be identical.

Allowed terminal/security outcomes are explicit and finite. At minimum:

- `PASS`
- `BLOCKED`
- `UNKNOWN`

No implicit success, timeout success, fallback success or heuristic promotion is permitted.

## 5. Forbidden Dependencies

Control MUST NOT use as an authorization decision dependency:

- LLM-generated PASS/FAIL classification;
- model confidence score;
- model ranking;
- natural-language interpretation of policy;
- AI consensus;
- external chat response;
- Telegram callback/button state;
- mutable prompt text;
- unverified GitHub comment as authority;
- non-deterministic external service response without a deterministic verification contract.

External services may provide data that Control verifies against deterministic rules, but the service response itself is never authority.

## 6. Canonicalization

Before policy evaluation, all security-relevant structured inputs MUST be canonicalized.

Canonicalization must define:

- field names;
- field types;
- required/optional fields;
- encoding;
- ordering;
- normalization rules;
- representation of null/absent values;
- hash input boundaries.

Two semantically identical authorized requests must not produce ambiguous security identities because of serialization differences.

## 7. Policy Version Binding

Every protected decision MUST bind to an explicit policy version.

Changing a security-relevant policy changes the canonical policy identity and invalidates previously issued decisions/authorizations where applicable.

Control MUST fail closed when the required policy version is missing, unknown or incompatible.

## 8. State and Time

Control decisions must use explicitly defined state and trusted time semantics.

- authorization expiry is deterministic;
- nonce consumption is atomic;
- replay detection is deterministic;
- terminal states cannot be reopened;
- timeout cannot imply success;
- missing state cannot imply success.

## 9. AI Boundary

AI components remain outside the Control authority boundary:

`Supervisor / Orchestrator / Architect / Researcher / Implementer / Reviewer / Evidence`

They may create proposals, evidence or implementation artifacts. Control verifies structured claims against pinned policy and protected state.

If an AI attempts to modify authority, scope, policy, approval state or protected state outside its assigned interface, Control MUST reject the operation.

## 10. Determinism Test — CTRL-01

The implementation MUST provide a non-production deterministic test that:

1. constructs a canonical valid input;
2. evaluates it N times in isolated repetitions;
3. records the complete decision output and deterministic fingerprint;
4. verifies every repetition is identical;
5. repeats with controlled mutation of each security-relevant input;
6. verifies that the expected decision changes only according to the pinned policy.

Minimum evidence:

- implementation/version identity;
- policy version/hash;
- canonical input hash;
- iteration count;
- output fingerprints;
- final PASS/BLOCKED result;
- runtime environment identity.

Recommended initial iteration count: `N >= 1000` for the deterministic function, followed by adversarial mutation cases.

## 11. CTRL-02 — AI Output Substitution Test

Provide Control with adversarial AI outputs including:

- `PASS`;
- `APPROVED`;
- fabricated human approval;
- high-confidence approval;
- multi-model consensus;
- prompt-injected instruction;
- malformed output.

Expected result: AI text alone has no authority and cannot change the deterministic decision.

## 12. CTRL-03 — UNKNOWN/FAIL Closure Test

For missing evidence, unknown state, malformed authorization, policy mismatch, stale state and verification timeout:

Expected result: `BLOCKED` or explicitly defined non-authorizing `UNKNOWN` where the surrounding state machine immediately blocks progression.

No test case may permit implicit promotion to `PASS`.

## 13. CTRL-04 — Environment Reproducibility

The same pinned Control release and policy must produce the same result across supported controlled runtime instances.

Environment-dependent values may be used only when explicitly defined as trusted inputs. Randomness may not influence an authorization decision unless it is an explicitly recorded security nonce/challenge whose verification semantics are deterministic.

## 14. CTRL-05 — Mutation Boundary Test

A successful Control decision must still be unable to mutate Core unless all independent authority, database privilege and operation-specific gates are satisfied.

Control determinism does not replace database least privilege.

Expected result for an unauthorized mutation attempt: database/network/security boundary rejects it.

## 15. Implementation Requirements

The implementation must:

- be independently unit-testable;
- expose a narrow typed interface;
- avoid direct LLM SDK dependencies;
- avoid prompt-driven policy;
- produce structured decision records;
- expose deterministic fingerprints for evidence;
- preserve policy/version identity;
- fail closed on schema or policy errors;
- keep protected mutation capability outside the general AI runtime.

## 16. Exit Criteria for P0-3

P0-3 is considered closed only when all are true:

1. Control implementation is demonstrably non-LLM and deterministic.
2. CTRL-01 passes with real non-production runtime evidence.
3. CTRL-02 passes.
4. CTRL-03 passes.
5. CTRL-04 passes where multiple controlled runtime instances are available.
6. CTRL-05 passes.
7. Independent adversarial review confirms the boundary.
8. Evidence is committed to the governance record.

Until then: **P0-3 OPEN / M15-A NOT READY / production mutation BLOCKED.**
