from __future__ import annotations
from dataclasses import dataclass
from typing import Mapping, Protocol

from .communication.core import TaskEnvelope, TaskState

@dataclass(frozen=True)
class ModelRequest:
    task_id: str
    correlation_id: str
    model: str
    prompt: str
    scope: str

@dataclass(frozen=True)
class ModelResponse:
    task_id: str
    correlation_id: str
    model: str
    content: str
    raw_status: str = "RECEIVED"

class ModelProvider(Protocol):
    def generate(self, request: ModelRequest) -> ModelResponse: ...

class ModelAdapter:
    """Untrusted model boundary. Provider output is data; it is never authority."""

    def __init__(self, providers: Mapping[str, ModelProvider], *, model: str) -> None:
        if not model or model not in providers:
            raise ValueError("MODEL_PROVIDER_NOT_REGISTERED")
        self._providers = dict(providers)
        self._model = model

    def execute(self, task: TaskEnvelope, prompt: str) -> ModelResponse:
        if task.status is not TaskState.ROUTING:
            raise ValueError("MODEL_EXECUTION_REQUIRES_ROUTED_TASK")
        if not prompt or not prompt.strip():
            raise ValueError("EMPTY_MODEL_PROMPT")
        response = self._providers[self._model].generate(
            ModelRequest(str(task.task_id), str(task.correlation_id), self._model, prompt, task.scope)
        )
        if response.task_id != str(task.task_id) or response.correlation_id != str(task.correlation_id):
            raise ValueError("MODEL_RESPONSE_ID_MISMATCH")
        if response.model != self._model:
            raise ValueError("MODEL_RESPONSE_PROVIDER_MISMATCH")
        if not response.content.strip():
            raise ValueError("EMPTY_MODEL_RESPONSE")
        if response.content.strip().upper() == "APPROVED":
            raise ValueError("MODEL_CANNOT_ASSERT_APPROVAL")
        return response

class FakeProvider:
    """Deterministic test provider. No network, credentials or production side effects."""

    def __init__(self, content: str = "TEST_RESPONSE") -> None:
        self.content = content

    def generate(self, request: ModelRequest) -> ModelResponse:
        return ModelResponse(request.task_id, request.correlation_id, request.model, self.content)
