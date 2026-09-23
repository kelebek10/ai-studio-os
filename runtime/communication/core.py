from __future__ import annotations
from dataclasses import dataclass, field
from enum import Enum
from typing import Any
from uuid import UUID, uuid4

class TaskState(str, Enum):
    VALIDATED="VALIDATED"; ROUTING="ROUTING"; EXECUTING="EXECUTING"; REVIEW="REVIEW"; EVIDENCE="EVIDENCE"; COMPLETED="COMPLETED"; BLOCKED="BLOCKED"; HUMAN_GATE="HUMAN_GATE"

VALID_TRANSITIONS = {
    TaskState.VALIDATED: {TaskState.ROUTING, TaskState.BLOCKED},
    TaskState.ROUTING: {TaskState.EXECUTING, TaskState.BLOCKED},
    TaskState.EXECUTING: {TaskState.REVIEW, TaskState.BLOCKED},
    TaskState.REVIEW: {TaskState.EVIDENCE, TaskState.BLOCKED},
    TaskState.EVIDENCE: {TaskState.COMPLETED, TaskState.BLOCKED, TaskState.HUMAN_GATE},
    TaskState.COMPLETED: set(),
    TaskState.BLOCKED: set(),
    TaskState.HUMAN_GATE: set(),
}

MAX_CONFLICT_ROUNDS = 3

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
    conflict_round: int = 0
    logical_problem_id: UUID | None = None
    parent_task_id: UUID | None = None
    requires_human: bool = False

    @staticmethod
    def new(agent: str, task_type: str, scope: str, source_commit: str, required_evidence: list[str], prohibited_actions: list[str], *, requires_human: bool = False, parent_task_id: UUID | None = None, logical_problem_id: UUID | None = None) -> "TaskEnvelope":
        if not all((agent, task_type, scope, source_commit)) or not required_evidence:
            raise ValueError("INVALID_TASK_ENVELOPE")
        return TaskEnvelope(uuid4(), uuid4(), agent, task_type, scope, source_commit, tuple(required_evidence), tuple(prohibited_actions), requires_human=requires_human, parent_task_id=parent_task_id, logical_problem_id=logical_problem_id)

    def transition(self, status: TaskState) -> "TaskEnvelope":
        if status == TaskState.HUMAN_GATE and not self.requires_human:
            raise ValueError("HUMAN_GATE_REQUIRES_DECLARATION")
        if status not in VALID_TRANSITIONS[self.status]:
            raise ValueError(f"INVALID_TRANSITION:{self.status}->{status}")
        return self.__class__(self.task_id, self.correlation_id, self.agent, self.task_type, self.scope, self.source_commit, self.required_evidence, self.prohibited_actions, status, self.result, self.evidence, self.conflict_round, self.logical_problem_id, self.parent_task_id, self.requires_human)

    def next_conflict_round(self) -> "TaskEnvelope":
        next_round = self.conflict_round + 1
        if next_round > MAX_CONFLICT_ROUNDS:
            return self.__class__(self.task_id, self.correlation_id, self.agent, self.task_type, self.scope, self.source_commit, self.required_evidence, self.prohibited_actions, TaskState.BLOCKED, self.result, self.evidence, next_round, self.logical_problem_id, self.parent_task_id, self.requires_human)
        return self.__class__(self.task_id, self.correlation_id, self.agent, self.task_type, self.scope, self.source_commit, self.required_evidence, self.prohibited_actions, self.status, self.result, self.evidence, next_round, self.logical_problem_id, self.parent_task_id, self.requires_human)

    def transition_name(self, status: str) -> "TaskEnvelope":
        if status == "APPROVED":
            raise ValueError("APPROVED_IS_NOT_A_TASK_STATE")
        try:
            target = TaskState(status)
        except ValueError as exc:
            raise ValueError(f"INVALID_STATUS:{status}") from exc
        return self.transition(target)

def create_task(**kwargs) -> TaskEnvelope:
    return TaskEnvelope.new(**kwargs)

def authorize_problem_round(*, declared: bool, round_number: int, max_rounds: int = 3, scope_match: bool = True, actionable: bool = True) -> ControlDecision:
    if not declared or not scope_match or not actionable:
        return ControlDecision.BLOCKED
    if round_number < 1 or round_number > max_rounds:
        return ControlDecision.BLOCKED
    return ControlDecision.ALLOW
