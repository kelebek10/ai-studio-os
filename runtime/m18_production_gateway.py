from __future__ import annotations

import json
import os
from http.server import BaseHTTPRequestHandler, HTTPServer

import psycopg

from runtime.communication.core import TaskEnvelope
from runtime.model_adapter import ModelAdapter
from runtime.ollama_provider import OllamaProvider
from runtime.orchestrator import Orchestrator
from runtime.orchestrator_pipeline import OrchestratorPipeline
from runtime.persistent_agent_registry import PersistentAgentRegistry
from runtime.provider_contract import Provider

HOST = "0.0.0.0"
PORT = int(os.getenv("M18_PORT", "8091"))
DB_DSN = os.environ["M18_DATABASE_DSN"]
AGENT_ID = os.environ["M18_AGENT_ID"]
SOURCE_COMMIT = os.environ["M18_SOURCE_COMMIT"]
MODEL = os.getenv("M18_MODEL", "qwen3:1.7b")
OLLAMA_URL = os.getenv("M18_OLLAMA_URL", "http://ollama:11434")


def make_pipeline():
    conn = psycopg.connect(DB_DSN, autocommit=True)
    registry = PersistentAgentRegistry(conn)
    agent = registry.get(AGENT_ID)
    if agent is None or agent.status.value != "ACTIVE":
        raise RuntimeError("M18_AGENT_NOT_REGISTERED_OR_INACTIVE")
    if agent.provider != Provider.QWEN.value:
        raise RuntimeError("M18_AGENT_PROVIDER_MISMATCH")
    adapter = ModelAdapter({MODEL: OllamaProvider(base_url=OLLAMA_URL, model=MODEL)}, model=MODEL)
    orchestrator = Orchestrator(registry)
    return conn, registry, orchestrator, OrchestratorPipeline(orchestrator, adapter)


class Handler(BaseHTTPRequestHandler):
    def _send(self, status, payload):
        body = json.dumps(payload, default=str).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def do_GET(self):
        if self.path == "/health":
            try:
                conn, registry, _, _ = make_pipeline()
                conn.close()
                return self._send(200, {"status": "ok", "service": "m18-runtime-gateway", "governance": "persistent-bounded", "agent_id": AGENT_ID})
            except Exception as exc:
                return self._send(503, {"status": "not_ready", "error": type(exc).__name__})
        if self.path == "/governance":
            return self._send(200, {"core_limit": 12, "specialist_limit": 36, "provider_limit": 9, "agent_creation": "no_http_authority", "approval": "human_only"})
        return self._send(404, {"error": "NOT_FOUND"})

    def do_POST(self):
        if self.path != "/task":
            return self._send(404, {"error": "NOT_FOUND"})
        try:
            raw = self.rfile.read(int(self.headers.get("Content-Length", "0")))
            if len(raw) > 8192:
                return self._send(413, {"error": "REQUEST_TOO_LARGE"})
            payload = json.loads(raw or b"{}")
            if not isinstance(payload, dict):
                return self._send(400, {"error": "INVALID_JSON_OBJECT"})
            allowed = {"prompt", "requires_human"}
            if set(payload) - allowed:
                return self._send(403, {"error": "CONTROL_FIELD_FORBIDDEN"})
            if "requires_human" in payload and not isinstance(payload["requires_human"], bool):
                return self._send(400, {"error": "INVALID_REQUIRES_HUMAN"})
            prompt = str(payload.get("prompt", "M18 production convergence"))
            if not prompt or len(prompt) > 2000:
                return self._send(400, {"error": "INVALID_PROMPT"})
            requires_human = payload.get("requires_human", True)
            conn, registry, orchestrator, pipeline = make_pipeline()
            try:
                task = TaskEnvelope.new(
                    agent=AGENT_ID,
                    task_type="PRODUCTION_RESEARCH",
                    scope="TASK_SCOPED",
                    source_commit=SOURCE_COMMIT,
                    required_evidence=["model_response", "review", "provenance"],
                    prohibited_actions=["APPROVE", "PROVISION"],
                    requires_human=requires_human,
                )
                result = pipeline.run(task, Provider.QWEN, prompt)
                return self._send(200, {"status": result.status.value, "review": result.review.verdict, "evidence_digest": result.evidence.evidence_digest, "human_gate": result.human_gate is not None, "correlation_id": str(task.correlation_id)})
            finally:
                conn.close()
        except Exception as exc:
            return self._send(403, {"error": type(exc).__name__, "reason": str(exc)})

    def log_message(self, *_):
        pass


HTTPServer((HOST, PORT), Handler).serve_forever()
