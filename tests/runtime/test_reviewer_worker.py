import pytest

from runtime.communication import TaskState, create_task
from runtime.model_adapter import FakeProvider, ModelAdapter
from runtime.reviewer_worker import ReviewerWorker


def make(agent="reviewer", evidence=("review_response",)):
    return create_task(
        agent=agent,
        task_type="REVIEW",
        scope="m16.6",
        source_commit="test",
        required_evidence=list(evidence),
        prohibited_actions=["free_chat", "self_approval"],
    )


def worker(content="REVIEW_RESULT"):
    return ReviewerWorker(
        ModelAdapter(
            {"qwen3:1.7b": FakeProvider(content)},
            model="qwen3:1.7b",
        )
    )


def test_reviewer_reviews_independently_and_preserves_source_identity():
    task = make().transition(TaskState.ROUTING)
    executing, result = worker().execute(
        task,
        source_task_id="research-task-001",
        research_content="candidate research",
        prompt="Identify unsupported claims and missing evidence.",
    )
    assert executing.status is TaskState.EXECUTING
    assert result.source_task_id == "research-task-001"
    assert result.verdict == "REVIEWED"
    assert result.content == "REVIEW_RESULT"
    assert result.scope == "m16.6"


def test_reviewer_rejects_wrong_role():
    task = make("researcher").transition(TaskState.ROUTING)
    with pytest.raises(PermissionError, match="ROLE_MISMATCH"):
        worker().execute(task, source_task_id="r1", research_content="x", prompt="review")


def test_reviewer_requires_evidence():
    task = make(evidence=()).transition(TaskState.ROUTING)
    with pytest.raises(ValueError, match="REQUIRES_EVIDENCE"):
        worker().execute(task, source_task_id="r1", research_content="x", prompt="review")


def test_reviewer_requires_source_content():
    task = make().transition(TaskState.ROUTING)
    with pytest.raises(ValueError, match="SOURCE_CONTENT"):
        worker().execute(task, source_task_id="r1", research_content=" ", prompt="review")


def test_reviewer_rejects_unrouted():
    with pytest.raises(ValueError, match="ROUTED"):
        worker().execute(make(), source_task_id="r1", research_content="x", prompt="review")


def test_reviewer_rejects_approval_output():
    task = make().transition(TaskState.ROUTING)
    with pytest.raises(ValueError, match="APPROVAL"):
        worker("APPROVED").execute(task, source_task_id="r1", research_content="x", prompt="review")
