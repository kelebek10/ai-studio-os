from __future__ import annotations
from dataclasses import dataclass
from typing import Any, Callable

from .core import TaskEnvelope, TaskState

@dataclass(frozen=True)
class Ack:
    task_id: str
    correlation_id: str
    status: str = "ACK"

@dataclass(frozen=True)
class Result:
    task_id: str
    correlation_id: str
    status: str
    result: dict[str, Any]
    evidence: tuple[dict[str, Any], ...]

class ControlledDispatcher:
    """Minimal deterministic task trigger; no free-form message path exists."""
    def __init__(self) -> None:
        self._handlers: dict[str, Callable[[TaskEnvelope], dict[str, Any]]] = {}
        self._completed: dict[tuple[str, str], Result] = {}

    def register(self, agent: str, handler: Callable[[TaskEnvelope], dict[str, Any]]) -> None:
        if not agent or agent in self._handlers:
            raise ValueError("INVALID_AGENT_REGISTRATION")
        self._handlers[agent] = handler

    def dispatch(self, task: TaskEnvelope) -> tuple[Ack, Result]:
        key = (str(task.task_id), str(task.correlation_id))
        if key in self._completed:
            result = self._completed[key]
            return Ack(result.task_id, result.correlation_id), result
        handler = self._handlers.get(task.agent)
        if handler is None:
            raise PermissionError("UNAUTHORIZED_OR_UNAVAILABLE_TARGET")
        ack = Ack(str(task.task_id), str(task.correlation_id))
        payload = handler(task)
        result = Result(
            str(task.task_id), str(task.correlation_id), "COMPLETED",
            payload, ({"type": "execution", "source": task.agent},)
        )
        self._completed[key] = result
        return ack, result
