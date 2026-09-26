import hashlib

class DeliveryStore:
    def __init__(self):
        self.receipts = {}

    def send(self, artifact, chat_id, transport='mock'):
        if artifact.get('status') != 'READY_FOR_DELIVERY':
            return 'BLOCKED_ARTIFACT_NOT_READY'
        if artifact.get('mime_type') != 'image/webp' or not artifact.get('sha256'):
            return 'BLOCKED_INVALID_ARTIFACT'
        if not chat_id:
            return 'BLOCKED_MISSING_DESTINATION'
        key = chat_id + ':' + artifact['render_id'] + ':' + artifact['sha256']
        if key in self.receipts:
            return self.receipts[key]
        if transport != 'mock':
            return 'READY_FOR_TELEGRAM'
        self.receipts[key] = 'DELIVERED'
        return 'DELIVERED'

store = DeliveryStore()
sha = hashlib.sha256(b'validated-webp').hexdigest()
ready = {'render_id':'R-001','status':'READY_FOR_DELIVERY','mime_type':'image/webp','sha256':sha}
assert store.send(ready, 'CHAT-001') == 'DELIVERED'
assert store.send(ready, 'CHAT-001') == 'DELIVERED'
assert store.send(dict(ready, status='READY_FOR_PROVIDER'), 'CHAT-001') == 'BLOCKED_ARTIFACT_NOT_READY'
assert store.send(dict(ready, sha256=''), 'CHAT-001') == 'BLOCKED_INVALID_ARTIFACT'
assert store.send(ready, '') == 'BLOCKED_MISSING_DESTINATION'
assert store.send(ready, 'CHAT-002', transport='telegram') == 'READY_FOR_TELEGRAM'
print('M21.20 Telegram delivery: 5/5 PASS')
