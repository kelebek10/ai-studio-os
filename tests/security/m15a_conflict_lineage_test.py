"""Reference tests for deterministic 3-round conflict lineage enforcement.

These tests define the required behavior for the future runtime enforcement layer.
They are not runtime evidence until executed against the real Control implementation.
"""

from dataclasses import dataclass


@dataclass(frozen=True)
class ConflictState:
    conflict_id: str
    logical_problem_id: str
    round_number: int
    terminal: bool = False


def authorize_round(previous: ConflictState, requested_round: int, logical_problem_id: str):
    if logical_problem_id != previous.logical_problem_id:
        return "BLOCKED / NEW_LOGICAL_PROBLEM_REQUIRES_CONTROL"
    if previous.terminal:
        return "BLOCKED / CONFLICT_TERMINAL_STATE"
    if requested_round != previous.round_number + 1:
        return "BLOCKED / INVALID_CONFLICT_ROUND"
    if requested_round > 3:
        return "BLOCKED / CONFLICT_ROUND_LIMIT_EXCEEDED"
    return "ALLOW"


def test_conf01_new_task_id_inherits_lineage():
    state = ConflictState("c-1", "lp-1", 2)
    assert authorize_round(state, 3, "lp-1") == "ALLOW"


def test_conf02_round4_is_denied():
    state = ConflictState("c-1", "lp-1", 3)
    assert authorize_round(state, 4, "lp-1") == "BLOCKED / CONFLICT_ROUND_LIMIT_EXCEEDED"


def test_conf03_agent_or_provider_change_cannot_reset_counter():
    state = ConflictState("c-1", "lp-1", 3)
    assert authorize_round(state, 1, "lp-1") == "BLOCKED / INVALID_CONFLICT_ROUND"


def test_conf04_new_conversation_cannot_reset_counter():
    state = ConflictState("c-1", "lp-1", 3)
    assert authorize_round(state, 4, "lp-1") != "ALLOW"


def test_conf05_identical_argument_cannot_create_round4():
    state = ConflictState("c-1", "lp-1", 3)
    assert authorize_round(state, 4, "lp-1") == "BLOCKED / CONFLICT_ROUND_LIMIT_EXCEEDED"


def test_conf06_unresolved_round3_is_terminal():
    state = ConflictState("c-1", "lp-1", 3, terminal=True)
    assert authorize_round(state, 4, "lp-1") == "BLOCKED / CONFLICT_TERMINAL_STATE"


def test_conf07_new_cycle_requires_controlled_new_problem():
    state = ConflictState("c-1", "lp-1", 3, terminal=True)
    assert authorize_round(state, 1, "lp-2") == "BLOCKED / NEW_LOGICAL_PROBLEM_REQUIRES_CONTROL"
