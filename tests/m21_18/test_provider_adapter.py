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
