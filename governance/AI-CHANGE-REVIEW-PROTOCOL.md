# PAI-FORGE — AI Change Review Protocol v1.0

**Status:** CONTROLLED REVIEW PROTOCOL
**Branch:** `phase-1-3-foundation`

## Review Sequence

1. Confirm task scope.
2. Confirm source branch and commit.
3. Inspect changed files and surrounding architecture.
4. Run applicable tests.
5. Check security and governance boundaries.
6. Check evidence integrity.
7. Check for regressions and duplicated logic.
8. Record PASS, BLOCKED, UNVERIFIED or NOT EXECUTED.
9. Create/update PR only when the implementation is ready for review.
10. Human approval remains required for protected merge decisions.

## Two-AI Review

When both ChatGPT and Claude participate:

- the implementer does not self-certify critical security changes;
- the second AI performs an independent review;
- disagreements are preserved until resolved by evidence or Human Project Owner decision;
- neither AI may convert an unresolved disagreement into PASS.

## Security-Critical Changes

For authorization, deterministic Control, provenance, privilege, network isolation, production deployment or other P0/P1 changes:

- real runtime evidence is required;
- documentation-only claims are insufficient;
- test output must identify the implementation/version under test;
- production mutation remains blocked until the applicable gate is closed.

## Merge Rule

A PR is not equivalent to approval. A review is not equivalent to human authorization. A passing test is not equivalent to production readiness.
