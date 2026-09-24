from __future__ import annotations

import json
from urllib.request import Request, urlopen

from .model_adapter import ModelRequest, ModelResponse


class OllamaProvider:
    """Live Ollama completion provider. Output remains untrusted model data."""

    def __init__(self, *, base_url: str = "http://127.0.0.1:11434", model: str = "qwen3:1.7b", timeout: int = 90) -> None:
        self.base_url = base_url.rstrip("/")
        self.model = model
        self.timeout = timeout

    def generate(self, request: ModelRequest) -> ModelResponse:
        payload = json.dumps({
            "model": self.model,
            "prompt": request.prompt,
            "stream": False,
            "think": False,
        }).encode("utf-8")
        req = Request(
            f"{self.base_url}/api/generate",
            data=payload,
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urlopen(req, timeout=self.timeout) as response:
            data = json.loads(response.read().decode("utf-8"))
        content = str(data.get("response", "")).strip()
        return ModelResponse(
            task_id=request.task_id,
            correlation_id=request.correlation_id,
            model=self.model,
            content=content,
            raw_status="OLLAMA_RECEIVED",
        )
