import os
from runtime.telegram_delivery_adapter import TelegramDeliveryAdapter

ARTIFACT = {
    'render_id':'M21-22-LIVE-001',
    'sha256':'DEMO-SHA-256',
    'status':'READY_FOR_DELIVERY',
    'mime_type':'image/webp',
}

# Live execution is deliberately fail-closed when the runtime secret is absent.
os.environ.pop('TELEGRAM_BOT_TOKEN', None)
adapter = TelegramDeliveryAdapter()
assert adapter.prepare('707822641', ARTIFACT).status == 'BLOCKED_MISSING_CREDENTIAL'

# With a synthetic token, the adapter may prepare a transport request but does not send.
prepared = TelegramDeliveryAdapter(token='TEST_ONLY_TOKEN').prepare('707822641', ARTIFACT)
assert prepared.status == 'READY_FOR_TELEGRAM'
assert prepared.attempts == 0

# A real live test requires both an explicit runtime secret and an authorized destination.
print('M21.22 live gate: 2/2 PASS')
print('LIVE_SEND: BLOCKED_MISSING_CREDENTIAL (expected; no secret installed)')
