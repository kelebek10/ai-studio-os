"""Deterministic non-production conflict-lineage control for PAI-FORGE."""
from __future__ import annotations
from dataclasses import dataclass
from enum import Enum

class ConflictDecision(str, Enum):
    ALLOW = "ALLOW"
    BLOCKED = "BLOCKED"

@dataclass(frozen=True)
class ConflictState:
    conflict_id: str
    root_task_id: str
    correlation_id: str
    logical_problem_id: str
    round_number: int
    terminal: bool = False

@dataclass(frozen=True)
class RoundRequest:
    logical_problem_id: str
    requested_round: int
    materially_new_evidence: bool = False
    materially_new_objective: bool = False

@dataclass(frozen=True)
class ControlDecision:
    decision: ConflictDecision
    reason: str

def authorize_round(state: ConflictState, request: RoundRequest) -> ControlDecision:
    """Pure deterministic gate; no LLM, network, DB or notification dependency."""
    if not state.logical_problem_id or not request.logical_problem_id:
        return ControlDecision(ConflictDecision.BLOCKED, "MISSING_LOGICAL_PROBLEM_ID")
    if request.logical_problem_id != state.logical_problem_id:
        return ControlDecision(ConflictDecision.BLOCKED, "NEW_LOGICAL_PROBLEM_REQUIRES_CONTROL")
    if state.terminal:
        return ControlDecision(ConflictDecision.BLOCKED, "CONFLICT_TERMINAL_STATE")
    if request.requested_round != state.round_number + 1:
        return ControlDecision(ConflictDecision.BLOCKED, "INVALID_CONFLICT_ROUND")
    if request.requested_round > 3:
        return ControlDecision(ConflictDecision.BLOCKED, "CONFLICT_ROUND_LIMIT_EXCEEDED")
    if request.requested_round >= 2 and not (request.materially_new_evidence or request.materially_new_objective):
        return ControlDecision(ConflictDecision.BLOCKED, "NO_MATERIAL_CHANGE_FOR_NEXT_ROUND")
    return ControlDecision(ConflictDecision.ALLOW, "ROUND_AUTHORIZED")
