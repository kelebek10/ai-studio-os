from __future__ import annotations
from dataclasses import dataclass
from .communication.core import TaskEnvelope, TaskState

@dataclass(frozen=True)
class SecurityDecision:
    allowed: bool
    reason: str

class SecurityGate:
    """Independent fail-closed boundary between evidence and human gate."""

    def inspect(self, task: TaskEnvelope) -> SecurityDecision:
        if task.status is not TaskState.EVIDENCE:
            return SecurityDecision(False, "SECURITY_REQUIRES_EVIDENCE_STATE")
        if not task.requires_human:
            return SecurityDecision(False, "SECURITY_REQUIRES_DECLARED_HUMAN_GATE")
        if not task.evidence:
            return SecurityDecision(False, "SECURITY_REQUIRES_EVIDENCE_RECORD")
        if task.result.get("approval") or task.result.get("approved_by"):
            return SecurityDecision(False, "SECURITY_REJECTS_ACTOR_SUPPLIED_APPROVAL")
        for item in task.evidence:
            if str(item.get("producer_status", "")).upper() == "APPROVED":
                return SecurityDecision(False, "SECURITY_REJECTS_EVIDENCE_APPROVAL_ASSERTION")
        return SecurityDecision(True, "SECURITY_CLEAR_FOR_HUMAN_GATE")
