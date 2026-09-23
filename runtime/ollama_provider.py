from __future__ import annotations
import json
from dataclasses import dataclass
from urllib import request
from .model_adapter import ModelRequest, ModelResponse

@dataclass(frozen=True)
class OllamaProvider:
    base_url: str = "http://127.0.0.1:11434"
    model: str = "qwen3:1.7b"
    timeout_seconds: float = 90.0

    def generate(self, request_data: ModelRequest) -> ModelResponse:
        if request_data.model != self.model:
            raise ValueError("OLLAMA_MODEL_MISMATCH")
        payload=json.dumps({"model":self.model,"prompt":request_data.prompt,"stream":False,"think":False}).encode()
        req=request.Request(self.base_url.rstrip("/")+"/api/generate",data=payload,headers={"Content-Type":"application/json"},method="POST")
        try:
            with request.urlopen(req,timeout=self.timeout_seconds) as resp:
                body=json.loads(resp.read().decode())
        except Exception as exc:
            raise RuntimeError("OLLAMA_PROVIDER_UNAVAILABLE") from exc
        content=body.get("response")
        if not isinstance(content,str):
            raise ValueError("OLLAMA_INVALID_RESPONSE")
        return ModelResponse(request_data.task_id,request_data.correlation_id,self.model,content,"RECEIVED")

    def health(self) -> bool:
        req=request.Request(self.base_url.rstrip("/")+"/api/tags",method="GET")
        try:
            with request.urlopen(req,timeout=min(self.timeout_seconds,5.0)) as resp:
                data=json.loads(resp.read().decode())
            return any(m.get("name")==self.model for m in data.get("models",[]))
        except Exception:
            return False
