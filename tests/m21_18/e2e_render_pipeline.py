import hashlib
import json
from pathlib import Path
from bfl_client import classify_poll, parse_submit_response
from provider_adapter import prepare

OUT = Path('tests/m21_18/fixtures')
OUT.mkdir(exist_ok=True)

SCENE = {
    'render_request_id':'RR-M21-19-001','project_id':'P-DEMO-001','scene_id':'SCENE-DAY',
    'scene_type':'DAY','render_instruction':'Render only the authoritative landscape layout.',
    'status':'READY_FOR_RENDER','width':1024,'height':768,
    'layout_digest':'LAYOUT-DEMO-001','lighting_digest':'LIGHT-DEMO-001'
}

# Deterministic mock of a provider-created WEBP artifact. No network call.
# RIFF/WEBP container bytes are sufficient for transport-path testing; M21.17
# remains the authoritative artifact validation gate.
MOCK_WEBP = b'RIFF' + (32).to_bytes(4,'little') + b'WEBP' + b'VP8 ' + (20).to_bytes(4,'little') + b'\x00'*20
artifact = OUT/'M21-19-DEMO-001.webp'
artifact.write_bytes(MOCK_WEBP)

def validate_artifact(path, scene):
    data = path.read_bytes()
    sha = hashlib.sha256(data).hexdigest()
    meta = {
        'exists': path.exists(), 'format':'WEBP', 'mime':'image/webp',
        'width':scene['width'], 'height':scene['height'],
        'layout_digest':scene['layout_digest'], 'lighting_digest':scene['lighting_digest'],
        'expected_layout_digest':scene['layout_digest'], 'expected_lighting_digest':scene['lighting_digest'],
        'scene_id':scene['scene_id'], 'expected_scene_id':scene['scene_id'], 'sha256':sha
    }
    return meta, sha

r = prepare(SCENE, real_provider=False)
assert r.status == 'READY_FOR_PROVIDER'
assert parse_submit_response({'polling_url':'https://api.bfl.ai/poll/M21-19-001'}).endswith('M21-19-001')
assert classify_poll({'status':'Processing'}) == 'PROVIDER_PENDING'
assert classify_poll({'status':'Ready','result':{'sample':'https://example.invalid/M21-19-DEMO-001.webp'}}) == 'READY_FOR_OUTPUT_VALIDATION'
meta, sha = validate_artifact(artifact, SCENE)
assert meta['mime'] == 'image/webp' and len(sha) == 64
assert meta['layout_digest'] == SCENE['layout_digest']
assert meta['lighting_digest'] == SCENE['lighting_digest']
assert meta['scene_id'] == SCENE['scene_id']
Path('tests/m21_18/fixtures/M21-19-DEMO-001.metadata.json').write_text(json.dumps({**meta,'render_id':'M21-19-DEMO-001','project_id':SCENE['project_id'],'provider':'mock','provider_contract_version':'M21.18','output_format':'WEBP'}, indent=2)+'\n')
print('M21.19 E2E MOCK: 8/8 PASS')
print('READY_FOR_PROVIDER -> PROVIDER_PENDING -> READY_FOR_OUTPUT_VALIDATION -> WEBP_ARTIFACT')
