from http.server import BaseHTTPRequestHandler, HTTPServer
import json

from runtime.agent_registry import AgentRegistry, HumanApproval, HUMAN
from runtime.communication.core import TaskEnvelope
from runtime.model_adapter import ModelAdapter
from runtime.ollama_provider import OllamaProvider
from runtime.orchestrator import Orchestrator
from runtime.orchestrator_pipeline import OrchestratorPipeline
from runtime.provider_contract import Provider

HOST = "0.0.0.0"
PORT = 8091
registry = AgentRegistry()
orchestrator = Orchestrator(registry)
core = registry.create_core("M18 Core", "TASK_SCOPED", HumanApproval("M18-SMOKE", HUMAN, "isolated smoke test"))
specialist = orchestrator.provision_specialist(name="Smoke", provider=Provider.QWEN, scope="TASK_SCOPED", parent_agent_id=core.agent_id)
adapter = ModelAdapter({"qwen3:1.7b": OllamaProvider(base_url="http://ollama:11434", model="qwen3:1.7b")}, model="qwen3:1.7b")
pipeline = OrchestratorPipeline(orchestrator, adapter)

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
            return self._send(200, {"status":"ok", "service":"m18-runtime-gateway", "governance":"bounded"})
        if self.path == "/governance":
            return self._send(200, {"core_limit":registry._limits[0], "specialist_limit":registry._limits[1], "provider_limit":registry._limits[2]})
        self._send(404, {"error":"NOT_FOUND"})

    def do_POST(self):
        if self.path != "/task":
            return self._send(404, {"error":"NOT_FOUND"})
        try:
            raw = self.rfile.read(int(self.headers.get("Content-Length", "0")))
            if len(raw) > 8192:
                return self._send(413, {"error":"REQUEST_TOO_LARGE"})
            payload = json.loads(raw or b"{}")
            if not isinstance(payload, dict):
                return self._send(400, {"error":"INVALID_JSON_OBJECT"})
            allowed = {"prompt", "requires_human"}
            if set(payload) - allowed:
                return self._send(403, {"error":"CONTROL_FIELD_FORBIDDEN"})
            if "requires_human" in payload and not isinstance(payload["requires_human"], bool):
                return self._send(400, {"error":"INVALID_REQUIRES_HUMAN"})
            prompt = str(payload.get("prompt", "M18 isolated smoke"))
            if not prompt or len(prompt) > 2000:
                return self._send(400, {"error":"INVALID_PROMPT"})
            requires_human = payload.get("requires_human", True)
            task = TaskEnvelope.new(agent=specialist.agent_id, task_type="SMOKE_RESEARCH", scope="TASK_SCOPED", source_commit="m18-live-qwen-smoke", required_evidence=["model_response", "review", "provenance"], prohibited_actions=["APPROVE", "PROVISION"], requires_human=requires_human)
            result = pipeline.run(task, Provider.QWEN, prompt)
            return self._send(200, {"status":result.status.value, "review":result.review.verdict, "evidence_digest":result.evidence.evidence_digest, "human_gate": result.human_gate is not None})
        except Exception as exc:
            return self._send(403, {"error":type(exc).__name__, "reason":str(exc)})

    def log_message(self, *_):
        pass

HTTPServer((HOST, PORT), Handler).serve_forever()
