import pytest
from runtime.communication import ControlDecision, TaskState, authorize_problem_round, create_task

def test_task_envelope_has_identity_and_scope():
    t=create_task(agent="test-agent",task_type="PING",scope="communication-core",source_commit="test",required_evidence=["ack"],prohibited_actions=["free_chat"])
    assert t.task_id and t.correlation_id and t.status is TaskState.VALIDATED
    assert t.agent == "test-agent"

def test_invalid_task_fails_closed():
    with pytest.raises(ValueError):
        create_task(agent="",task_type="PING",scope="x",source_commit="test",required_evidence=["ack"],prohibited_actions=[])

def test_three_round_rule_only_for_declared_problem_solving():
    assert authorize_problem_round(declared=False,round_number=1) is ControlDecision.BLOCKED
    assert authorize_problem_round(declared=True,round_number=1) is ControlDecision.ALLOW
    assert authorize_problem_round(declared=True,round_number=2) is ControlDecision.ALLOW
    assert authorize_problem_round(declared=True,round_number=3) is ControlDecision.ALLOW
    assert authorize_problem_round(declared=True,round_number=4) is ControlDecision.BLOCKED
    assert authorize_problem_round(declared=True,round_number=2,scope_match=False) is ControlDecision.BLOCKED
