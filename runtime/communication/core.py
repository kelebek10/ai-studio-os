from __future__ import annotations
from dataclasses import dataclass, field
from enum import Enum
from typing import Any
from uuid import UUID, uuid4

class TaskState(str, Enum):
    VALIDATED="VALIDATED"; ROUTING="ROUTING"; EXECUTING="EXECUTING"; COMPLETED="COMPLETED"; BLOCKED="BLOCKED"

class ControlDecision(str, Enum):
    ALLOW="ALLOW"; BLOCKED="BLOCKED"

@dataclass(frozen=True)
class TaskEnvelope:
    task_id: UUID
    correlation_id: UUID
    agent: str
    task_type: str
    scope: str
    source_commit: str
    required_evidence: tuple[str, ...]
    prohibited_actions: tuple[str, ...]
    status: TaskState = TaskState.VALIDATED
    result: dict[str, Any] = field(default_factory=dict)
    evidence: tuple[dict[str, Any], ...] = ()

    @staticmethod
    def new(agent: str, task_type: str, scope: str, source_commit: str, required_evidence: list[str], prohibited_actions: list[str]) -> "TaskEnvelope":
        if not all((agent, task_type, scope, source_commit)) or not required_evidence:
            raise ValueError("INVALID_TASK_ENVELOPE")
        return TaskEnvelope(uuid4(), uuid4(), agent, task_type, scope, source_commit, tuple(required_evidence), tuple(prohibited_actions))

def create_task(**kwargs) -> TaskEnvelope:
    return TaskEnvelope.new(**kwargs)

def authorize_problem_round(*, declared: bool, round_number: int, max_rounds: int = 3, scope_match: bool = True, actionable: bool = True) -> ControlDecision:
    if not declared or not scope_match or not actionable:
        return ControlDecision.BLOCKED
    if round_number < 1 or round_number > max_rounds:
        return ControlDecision.BLOCKED
    return ControlDecision.ALLOW
