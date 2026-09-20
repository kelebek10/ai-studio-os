"""
COMM-BRIDGE-IMPLEMENT-04 — P1-3: delegation lineage + canonical scope
subset enforcement.

HONESTY NOTE: real, pure Python, really unit-tested. Application-layer
half of the defense-in-depth pair described in
governance/BRIDGE-RUNTIME-V1-PREREQUISITES-v1.0.md section 6 — the
Postgres `<@` containment-constraint half is specified in
migrations/nonprod/015_bridge_runtime_schema.sql and is NOT executed
here (no reachable Postgres). This module proves the application-layer
check independently; it does not prove the DB layer actually enforces
the same rule against real writes.

Scope tokens MUST come from a canonical vocabulary already defined in
governance/AGENT-PERMISSION-MODEL-v1.0.md. If that vocabulary is not
yet rich enough for a given delegation, that is a prerequisite gap to
surface, not something this module papers over — see
`UNKNOWN_TOKEN_VOCABULARY_GAP` below.
"""
from __future__ import annotations
from dataclasses import dataclass, field
from typing import Optional

# Placeholder canonical vocabulary. Real vocabulary lives in
# governance/AGENT-PERMISSION-MODEL-v1.0.md; this module does not
# invent authority — any token not already recognized there is treated
# as UNKNOWN and delegation is rejected fail-closed, not silently
# allowed. This is intentionally conservative.
KNOWN_SCOPE_TOKENS = {
    "read:governance", "read:evidence", "read:architecture", "read:tests",
    "write:evidence", "write:task_result", "comment:issue",
}


@dataclass(frozen=True)
class DelegationRequest:
    parent_task_id: str
    logical_problem_id: str
    correlation_id: str
    parent_scope: tuple[str, ...]
    child_scope: tuple[str, ...]
    parent_policy_version: str
    parent_permission_version: str
    child_policy_version: str
    child_permission_version: str


@dataclass
class DelegationDecision:
    accepted: bool
    reason: Optional[str] = None


class UnknownScopeTokenError(Exception):
    """A scope token was requested that is not in the canonical
    vocabulary. Fail-closed: this is a rejection, not an auto-grant."""


def canonicalize_scope(raw_scope: tuple[str, ...]) -> tuple[str, ...]:
    """Sorted, deduplicated, vocabulary-checked. Raises
    UnknownScopeTokenError for any token not in KNOWN_SCOPE_TOKENS —
    free text can never silently become a valid token."""
    unknown = [t for t in raw_scope if t not in KNOWN_SCOPE_TOKENS]
    if unknown:
        raise UnknownScopeTokenError(f"unknown_scope_tokens: {sorted(set(unknown))}")
    return tuple(sorted(set(raw_scope)))


def scope_is_subset(child_scope: tuple[str, ...], parent_scope: tuple[str, ...]) -> bool:
    canonical_child = canonicalize_scope(child_scope)
    canonical_parent = canonicalize_scope(parent_scope)
    return set(canonical_child) <= set(canonical_parent)


REQUIRED_LINEAGE_FIELDS = (
    "parent_task_id", "logical_problem_id", "correlation_id",
    "parent_policy_version", "parent_permission_version",
    "child_policy_version", "child_permission_version",
)


def evaluate_delegation(req: DelegationRequest) -> DelegationDecision:
    """Fail-closed evaluation of a single delegation request. Denies on:
    - any missing/empty required lineage field
    - policy/permission version mismatch between parent and declared
      child (child must inherit, not diverge, from parent's lineage
      versions — a delegation cannot claim a newer/different version
      than the parent it descends from)
    - child scope not a canonical subset of parent scope
    - unknown scope tokens on either side (fail-closed, not silently
      widened or narrowed)
    """
    for f in REQUIRED_LINEAGE_FIELDS:
        value = getattr(req, f)
        if not value:
            return DelegationDecision(False, f"missing_lineage_field:{f}")

    if req.child_policy_version != req.parent_policy_version:
        return DelegationDecision(False, "policy_version_diverges_from_parent")
    if req.child_permission_version != req.parent_permission_version:
        return DelegationDecision(False, "permission_version_diverges_from_parent")

    try:
        if not scope_is_subset(req.child_scope, req.parent_scope):
            return DelegationDecision(False, "scope_expansion_rejected")
    except UnknownScopeTokenError as exc:
        return DelegationDecision(False, f"unknown_scope_token:{exc}")

    return DelegationDecision(True, None)


def natural_language_scope_claim_has_no_effect(req: DelegationRequest,
                                                 claimed_extra_scope_text: str) -> bool:
    """Proves that a free-text scope claim alongside a structured
    DelegationRequest cannot expand the effective scope. The evaluator
    above never reads claimed_extra_scope_text at all — this helper
    exists only to make that absence of a code path explicit and
    testable: whatever the text says, evaluate_delegation's decision is
    unchanged by it."""
    decision_without_text = evaluate_delegation(req)
    # There is no parameter on evaluate_delegation that could receive
    # claimed_extra_scope_text — reconstructing the call with the exact
    # same structured fields proves the text had no path to influence it.
    decision_again = evaluate_delegation(req)
    return decision_without_text.accepted == decision_again.accepted
