from __future__ import annotations
from dataclasses import dataclass
from .communication.core import TaskEnvelope, TaskState
from .security_gate import SecurityGate

@dataclass(frozen=True)
class HumanGateRequest:
    task_id: str
    correlation_id: str
    scope: str
    evidence_count: int
    security_reason: str
    human_action_required: bool = True

class HumanGate:
    """Creates a human-review request only. It cannot approve or mutate authority."""

    def __init__(self, security_gate: SecurityGate | None = None) -> None:
        self._security = security_gate or SecurityGate()

    def request(self, task: TaskEnvelope) -> tuple[TaskEnvelope, HumanGateRequest]:
        decision = self._security.inspect(task)
        if not decision.allowed:
            raise PermissionError(decision.reason)
        gated = task.transition(TaskState.HUMAN_GATE)
        return gated, HumanGateRequest(
            task_id=str(gated.task_id),
            correlation_id=str(gated.correlation_id),
            scope=gated.scope,
            evidence_count=len(gated.evidence),
            security_reason=decision.reason,
        )
