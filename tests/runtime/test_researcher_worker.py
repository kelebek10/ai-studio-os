import pytest

from runtime.communication import TaskState, create_task
from runtime.model_adapter import FakeProvider, ModelAdapter
from runtime.researcher_worker import ResearcherWorker


def make(agent="researcher", evidence=("model_response",)):
    return create_task(
        agent=agent,
        task_type="RESEARCH",
        scope="m16.5",
        source_commit="test",
        required_evidence=list(evidence),
        prohibited_actions=["free_chat"],
    )


def worker(content="candidate research"):
    return ResearcherWorker(
        ModelAdapter(
            {"qwen3:1.7b": FakeProvider(content)},
            model="qwen3:1.7b",
        )
    )


def test_researcher_executes_bounded_task():
    task = make().transition(TaskState.ROUTING)
    executing, result = worker().execute(task, "research")
    assert executing.status is TaskState.EXECUTING
    assert result.content == "candidate research"
    assert result.evidence_required == ("model_response",)
    assert result.task_id == str(executing.task_id)
    assert result.correlation_id == str(executing.correlation_id)


def test_researcher_rejects_wrong_role():
    task = make("reviewer").transition(TaskState.ROUTING)
    with pytest.raises(PermissionError, match="ROLE_MISMATCH"):
        worker().execute(task, "research")


def test_researcher_requires_evidence():
    task = make(evidence=()).transition(TaskState.ROUTING)
    with pytest.raises(ValueError, match="REQUIRES_EVIDENCE"):
        worker().execute(task, "research")


def test_researcher_rejects_unrouted():
    with pytest.raises(ValueError, match="ROUTED"):
        worker().execute(make(), "research")


def test_researcher_rejects_approval_output():
    task = make().transition(TaskState.ROUTING)
    with pytest.raises(ValueError, match="APPROVAL"):
        worker("APPROVED").execute(task, "research")
