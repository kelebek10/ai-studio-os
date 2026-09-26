from provider_adapter import prepare, mock_submit

BASE = {
    "render_request_id": "RR-001",
    "project_id": "P-001",
    "scene_id": "SCENE-DAY",
    "render_instruction": "Render the authoritative landscape layout without inventing geometry.",
    "status": "READY_FOR_RENDER",
}

r = prepare(BASE, real_provider=True)
assert r.status == "BLOCKED_MISSING_CREDENTIAL", r

m = mock_submit(BASE)
assert m.status == "READY_FOR_OUTPUT_VALIDATION", m
assert m.request["mime_type"] == "image/webp"

bad = dict(BASE)
bad.pop("scene_id")
assert prepare(bad, real_provider=False).status == "BLOCKED_INVALID_REQUEST"

print("M21.18 provider adapter: 3/3 PASS")

from bfl_client import build_http_request, parse_submit_response, classify_poll, ProviderError
import os

os.environ.pop("BFL_API_KEY", None)
try:
    build_http_request({"prompt":"x", "width":1024, "height":1024})
    raise AssertionError("credential gate failed")
except ProviderError as e:
    assert str(e) == "BLOCKED_MISSING_CREDENTIAL"

assert parse_submit_response({"polling_url":"https://api.bfl.ai/poll/test"}).endswith("/test")
assert classify_poll({"status":"Ready", "result":{"sample":"https://example.invalid/result.webp"}}) == "READY_FOR_OUTPUT_VALIDATION"
assert classify_poll({"status":"Failed"}) == "BLOCKED_PROVIDER_ERROR"
assert classify_poll({"status":"Processing"}) == "PROVIDER_PENDING"
print("M21.18 HTTP contract: 4/4 PASS")
