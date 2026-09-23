from __future__ import annotations
from dataclasses import dataclass

from .communication.core import TaskEnvelope, TaskState
from .model_adapter import ModelAdapter


@dataclass(frozen=True)
class ResearchResult:
    task_id: str
    correlation_id: str
    scope: str
    model: str
    content: str
    evidence_required: tuple[str, ...]


class ResearcherWorker:
    """Bounded research worker. It produces candidate research, never authority."""

    def __init__(self, adapter: ModelAdapter) -> None:
        self._adapter = adapter

    def execute(self, task: TaskEnvelope, prompt: str) -> tuple[TaskEnvelope, ResearchResult]:
        if task.agent != "researcher":
            raise PermissionError("WORKER_ROLE_MISMATCH")
        if task.status is not TaskState.ROUTING:
            raise ValueError("RESEARCHER_REQUIRES_ROUTED_TASK")
        if not task.required_evidence:
            raise ValueError("RESEARCHER_REQUIRES_EVIDENCE")

        executing = task.transition(TaskState.EXECUTING)
        response = self._adapter.execute(executing, prompt)
        if response.content.strip().upper() == "APPROVED":
            raise ValueError("MODEL_CANNOT_ASSERT_APPROVAL")

        result = ResearchResult(
            task_id=str(executing.task_id),
            correlation_id=str(executing.correlation_id),
            scope=executing.scope,
            model=response.model,
            content=response.content,
            evidence_required=executing.required_evidence,
        )
        return executing, result
