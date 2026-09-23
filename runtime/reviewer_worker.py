from __future__ import annotations
from dataclasses import dataclass

from .communication.core import TaskEnvelope, TaskState
from .model_adapter import ModelAdapter


@dataclass(frozen=True)
class ReviewResult:
    task_id: str
    correlation_id: str
    scope: str
    model: str
    source_task_id: str
    verdict: str
    content: str


class ReviewerWorker:
    """Independent bounded review worker. It reviews supplied work; it never grants authority."""

    def __init__(self, adapter: ModelAdapter) -> None:
        self._adapter = adapter

    def execute(
        self,
        task: TaskEnvelope,
        *,
        source_task_id: str,
        research_content: str,
        prompt: str,
    ) -> tuple[TaskEnvelope, ReviewResult]:
        if task.agent != "reviewer":
            raise PermissionError("WORKER_ROLE_MISMATCH")
        if task.status is not TaskState.ROUTING:
            raise ValueError("REVIEWER_REQUIRES_ROUTED_TASK")
        if not task.required_evidence:
            raise ValueError("REVIEWER_REQUIRES_EVIDENCE")
        if not source_task_id:
            raise ValueError("REVIEWER_REQUIRES_SOURCE_TASK")
        if not research_content.strip():
            raise ValueError("REVIEWER_REQUIRES_SOURCE_CONTENT")
        if not prompt.strip():
            raise ValueError("EMPTY_REVIEW_PROMPT")

        executing = task.transition(TaskState.EXECUTING)
        review_prompt = (
            f"{prompt.strip()}\n\n"
            "SOURCE TASK ID:\n" + source_task_id + "\n\n"
            "RESEARCH OUTPUT TO REVIEW:\n" + research_content.strip()
        )
        response = self._adapter.execute(executing, review_prompt)
        content = response.content.strip()
        if content.upper() == "APPROVED":
            raise ValueError("MODEL_CANNOT_ASSERT_APPROVAL")

        result = ReviewResult(
            task_id=str(executing.task_id),
            correlation_id=str(executing.correlation_id),
            scope=executing.scope,
            model=response.model,
            source_task_id=source_task_id,
            verdict="REVIEWED",
            content=content,
        )
        return executing, result
