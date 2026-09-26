from dataclasses import dataclass
from runtime.telegram_delivery_adapter import TelegramDeliveryAdapter

@dataclass(frozen=True)
class PipelineResult:
    status: str
    stage: str
    render_id: str
    error_code: str | None = None

class VisualArtifactOrchestrator:
    def __init__(self, telegram=None):
        self.telegram = telegram or TelegramDeliveryAdapter()

    def preflight(self, request, artifact, chat_id):
        rid = request.get("render_request_id", "")
        if request.get("status") != "READY_FOR_PROVIDER":
            return PipelineResult("BLOCKED_RENDER_REQUEST", "PREPARE", rid, "BLOCKED_RENDER_REQUEST")
        if artifact is None:
            return PipelineResult("BLOCKED_MISSING_ARTIFACT", "VALIDATE", rid, "BLOCKED_MISSING_ARTIFACT")
        receipt = self.telegram.prepare(chat_id or "", artifact)
        if receipt.status != "READY_FOR_TELEGRAM":
            return PipelineResult(receipt.status, "DELIVERY_GATE", rid, receipt.error_code)
        return PipelineResult("READY_FOR_DELIVERY", "DELIVERY_GATE", rid)
