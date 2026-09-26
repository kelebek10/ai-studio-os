from __future__ import annotations
import os
from dataclasses import dataclass
from urllib.parse import quote

@dataclass(frozen=True)
class DeliveryReceipt:
    delivery_id: str
    status: str
    attempts: int
    message_id: str | None = None
    error_code: str | None = None

class TelegramDeliveryAdapter:
    def __init__(self, token: str | None = None):
        self._token = token if token is not None else os.getenv('TELEGRAM_BOT_TOKEN', '')
        self._receipts: dict[str, DeliveryReceipt] = {}

    def _key(self, chat_id: str, artifact: dict) -> str:
        return f"{chat_id}:{artifact['render_id']}:{artifact['sha256']}"

    def prepare(self, chat_id: str, artifact: dict) -> DeliveryReceipt:
        if artifact.get('status') != 'READY_FOR_DELIVERY':
            return DeliveryReceipt('blocked', 'BLOCKED_ARTIFACT_NOT_READY', 0, error_code='BLOCKED_ARTIFACT_NOT_READY')
        if artifact.get('mime_type') != 'image/webp' or not artifact.get('sha256'):
            return DeliveryReceipt('blocked', 'BLOCKED_INVALID_ARTIFACT', 0, error_code='BLOCKED_INVALID_ARTIFACT')
        if not chat_id:
            return DeliveryReceipt('blocked', 'BLOCKED_MISSING_DESTINATION', 0, error_code='BLOCKED_MISSING_DESTINATION')
        key = self._key(chat_id, artifact)
        if key in self._receipts:
            return self._receipts[key]
        if not self._token:
            return DeliveryReceipt(key, 'BLOCKED_MISSING_CREDENTIAL', 0, error_code='BLOCKED_MISSING_CREDENTIAL')
        return DeliveryReceipt(key, 'READY_FOR_TELEGRAM', 0)

    def api_url(self) -> str:
        if not self._token:
            raise RuntimeError('BLOCKED_MISSING_CREDENTIAL')
        return 'https://api.telegram.org/bot' + quote(self._token, safe='') + '/sendDocument'
