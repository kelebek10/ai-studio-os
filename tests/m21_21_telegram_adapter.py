import os
from runtime.telegram_delivery_adapter import TelegramDeliveryAdapter

A = {'render_id':'R-21','sha256':'abc123','status':'READY_FOR_DELIVERY','mime_type':'image/webp'}

os.environ.pop('TELEGRAM_BOT_TOKEN', None)
a = TelegramDeliveryAdapter()
assert a.prepare('707822641', A).status == 'BLOCKED_MISSING_CREDENTIAL'
assert a.prepare('707822641', dict(A, status='READY_FOR_PROVIDER')).status == 'BLOCKED_ARTIFACT_NOT_READY'
assert a.prepare('', A).status == 'BLOCKED_MISSING_DESTINATION'
assert a.prepare('707822641', dict(A, mime_type='image/png')).status == 'BLOCKED_INVALID_ARTIFACT'

b = TelegramDeliveryAdapter(token='TEST_ONLY_TOKEN')
r = b.prepare('707822641', A)
assert r.status == 'READY_FOR_TELEGRAM'
assert b.api_url().endswith('/sendDocument')
print('M21.21 Telegram adapter contract: 5/5 PASS')
