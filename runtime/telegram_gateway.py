from __future__ import annotations
from dataclasses import dataclass
from uuid import UUID, uuid4
from .communication.core import TaskEnvelope

ALLOWED_COMMANDS = frozenset({"/status", "/missions", "/report", "/alerts", "/ask", "/pause", "/resume", "/logs"})
APPROVAL_COMMANDS = frozenset({"/approve"})

@dataclass(frozen=True)
class TelegramRequest:
    chat_id: int
    text: str
    update_id: str

@dataclass(frozen=True)
class GatewayDecision:
    allowed: bool
    reason: str
    command: str
    task: TaskEnvelope | None = None

class TelegramGateway:
    """Untrusted Telegram ingress. It creates task intent only; it grants no authority."""

    def __init__(self, allowed_chat_ids: set[int] | frozenset[int]) -> None:
        self._allowed = frozenset(allowed_chat_ids)

    def accept(self, request: TelegramRequest, *, source_commit: str) -> GatewayDecision:
        if request.chat_id not in self._allowed:
            return GatewayDecision(False, "TELEGRAM_CHAT_NOT_ALLOWED", "")
        text = request.text.strip()
        if not text:
            return GatewayDecision(False, "TELEGRAM_EMPTY_MESSAGE", "")
        command = text.split(maxsplit=1)[0].lower()
        if command in APPROVAL_COMMANDS:
            return GatewayDecision(False, "TELEGRAM_APPROVAL_REQUIRES_HUMAN_GATE", command)
        if command not in ALLOWED_COMMANDS:
            return GatewayDecision(False, "TELEGRAM_COMMAND_NOT_ALLOWED", command)
        task = TaskEnvelope.new(
            agent="orchestrator",
            task_type=f"telegram:{command[1:]}",
            scope="TELEGRAM_COMMAND_GATEWAY",
            source_commit=source_commit,
            required_evidence=["telegram-audit"],
            prohibited_actions=["direct_core_write", "governance_bypass", "self_approve"],
            logical_problem_id=UUID(int=uuid4().int),
            requires_human=(command in {"/pause", "/resume"}),
        )
        return GatewayDecision(True, "TELEGRAM_ACCEPTED_UNTRUSTED", command, task)
