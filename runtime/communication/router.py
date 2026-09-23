from __future__ import annotations
from dataclasses import dataclass
from typing import Mapping

from .core import TaskEnvelope, TaskState

@dataclass(frozen=True)
class Route:
    task_id: str
    correlation_id: str
    target: str
    status: TaskState

class OrchestratorRouter:
    """Deterministic routing boundary. It selects a registered worker; it never executes or approves."""

    def __init__(self, routes: Mapping[str, str]) -> None:
        self._routes = dict(routes)
        if any(not k or not v for k, v in self._routes.items()):
            raise ValueError("INVALID_ROUTE_TABLE")

    def route(self, task: TaskEnvelope) -> tuple[TaskEnvelope, Route]:
        if task.status is not TaskState.VALIDATED:
            raise ValueError("ROUTING_REQUIRES_VALIDATED_TASK")
        if task.agent not in self._routes:
            raise PermissionError("UNAUTHORIZED_OR_UNAVAILABLE_TARGET")
        target = self._routes[task.agent]
        if target in {"CORE", "HUMAN", "SUPERVISOR"}:
            raise PermissionError("ROUTER_CANNOT_ROUTE_TO_AUTHORITY_OR_CORE")
        routed = task.transition(TaskState.ROUTING)
        return routed, Route(str(task.task_id), str(task.correlation_id), target, routed.status)
