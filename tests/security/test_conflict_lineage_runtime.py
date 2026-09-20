from control.conflict_lineage import ConflictDecision, ConflictState, RoundRequest, authorize_round


def state(round_number=1, terminal=False):
    return ConflictState("c-1", "task-1", "corr-1", "lp-1", round_number, terminal)


def test_conf01_task_change_does_not_reset_lineage():
    s = state(2)
    assert authorize_round(s, RoundRequest("lp-1", 3, materially_new_evidence=True)).decision == ConflictDecision.ALLOW


def test_conf02_round4_denied():
    s = state(3)
    d = authorize_round(s, RoundRequest("lp-1", 4, materially_new_evidence=True))
    assert d.reason == "CONFLICT_ROUND_LIMIT_EXCEEDED"


def test_conf03_provider_or_agent_change_cannot_reset():
    s = state(3)
    d = authorize_round(s, RoundRequest("lp-1", 1, materially_new_evidence=True))
    assert d.decision == ConflictDecision.BLOCKED


def test_conf04_new_conversation_cannot_reset():
    s = state(3)
    d = authorize_round(s, RoundRequest("lp-1", 4, materially_new_evidence=True))
    assert d.decision == ConflictDecision.BLOCKED


def test_conf05_identical_argument_without_new_evidence_blocked():
    s = state(1)
    d = authorize_round(s, RoundRequest("lp-1", 2))
    assert d.reason == "NO_MATERIAL_CHANGE_FOR_NEXT_ROUND"


def test_conf06_terminal_round3_blocks_continuation():
    s = state(3, terminal=True)
    d = authorize_round(s, RoundRequest("lp-1", 4, materially_new_evidence=True))
    assert d.reason == "CONFLICT_TERMINAL_STATE"


def test_conf07_new_logical_problem_requires_control():
    s = state(3, terminal=True)
    d = authorize_round(s, RoundRequest("lp-2", 1, materially_new_evidence=True))
    assert d.reason == "NEW_LOGICAL_PROBLEM_REQUIRES_CONTROL"
