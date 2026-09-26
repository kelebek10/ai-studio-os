import os
from dataclasses import dataclass

MODEL_ENDPOINT = "https://api.bfl.ai/v1/flux-2-pro"

@dataclass(frozen=True)
class AdapterResult:
    status: str
    request: dict
    provider: str = "black-forest-labs"
    model: str = "flux-2-pro"


def normalize_request(scene: dict) -> dict:
    if scene.get("status") != "READY_FOR_RENDER":
        return {"status": "BLOCKED_INVALID_REQUEST"}
    required = ("render_request_id", "project_id", "scene_id", "render_instruction")
    if any(not scene.get(k) for k in required):
        return {"status": "BLOCKED_INVALID_REQUEST"}
    return {
        "prompt": scene["render_instruction"],
        "width": int(scene.get("width", 1024)),
        "height": int(scene.get("height", 1024)),
        "model": "flux-2-pro",
    }


def credential_gate() -> bool:
    key = os.environ.get("BFL_API_KEY", "")
    return bool(key and not key.startswith("PLACEHOLDER_"))


def prepare(scene: dict, real_provider: bool = False) -> AdapterResult:
    request = normalize_request(scene)
    if request.get("status") == "BLOCKED_INVALID_REQUEST":
        return AdapterResult("BLOCKED_INVALID_REQUEST", request)
    if real_provider and not credential_gate():
        return AdapterResult("BLOCKED_MISSING_CREDENTIAL", request)
    return AdapterResult("READY_FOR_PROVIDER", request)


def mock_submit(scene: dict) -> AdapterResult:
    result = prepare(scene, real_provider=False)
    if result.status != "READY_FOR_PROVIDER":
        return result
    return AdapterResult("READY_FOR_OUTPUT_VALIDATION", {
        **result.request,
        "mock": True,
        "mime_type": "image/webp",
        "fixture": "M21-MOCK-WEBP-001",
    })
