import json
import os
import urllib.request
import urllib.error

ENDPOINT = "https://api.bfl.ai/v1/flux-2-pro"

class ProviderError(RuntimeError):
    pass

def build_http_request(request: dict):
    key = os.environ.get("BFL_API_KEY", "")
    if not key or key.startswith("PLACEHOLDER_"):
        raise ProviderError("BLOCKED_MISSING_CREDENTIAL")
    body = json.dumps({
        "prompt": request["prompt"],
        "width": request["width"],
        "height": request["height"],
    }).encode()
    return urllib.request.Request(
        ENDPOINT,
        data=body,
        headers={"accept": "application/json", "x-key": key, "Content-Type": "application/json"},
        method="POST",
    )

def parse_submit_response(payload: dict) -> str:
    polling_url = payload.get("polling_url")
    if not polling_url:
        raise ProviderError("BLOCKED_PROVIDER_RESULT")
    return polling_url

def classify_poll(payload: dict) -> str:
    status = payload.get("status")
    if status == "Ready" and payload.get("result", {}).get("sample"):
        return "READY_FOR_OUTPUT_VALIDATION"
    if status in {"Error", "Failed", "Request Moderated", "Content Moderated"}:
        return "BLOCKED_PROVIDER_ERROR"
    return "PROVIDER_PENDING"
