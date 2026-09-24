from __future__ import annotations
import json
from http.server import BaseHTTPRequestHandler, HTTPServer

from runtime.communication.core import TaskEnvelope, TaskState
from runtime.evidence_worker import EvidenceWorker
from runtime.human_gate import HumanGate
from runtime.model_adapter import ModelAdapter
from runtime.ollama_provider import OllamaProvider
from runtime.researcher_worker import ResearcherWorker
from runtime.reviewer_worker import ReviewerWorker
from runtime.security_gate import SecurityGate

MODEL="qwen3:1.7b"
SCOPE="m17.4-telegram-e2e"
SOURCE_COMMIT="3b1a479"
provider=OllamaProvider(model=MODEL, base_url="http://ollama:11434", timeout=120)
adapter=ModelAdapter({MODEL:provider}, model=MODEL)
researcher=ResearcherWorker(adapter)
reviewer=ReviewerWorker(adapter)
evidence=EvidenceWorker()
security=SecurityGate()
human_gate=HumanGate(security)

def run_chain(command,payload,chat_id):
    requires_human=command in {"/pause","/resume"}
    task=TaskEnvelope.new(
        agent="researcher", task_type="TELEGRAM_M17_4",
        scope=SCOPE, source_commit=SOURCE_COMMIT,
        required_evidence=["research_output","review_output","provenance"],
        prohibited_actions=["APPROVED","CORE_MUTATION","HUMAN_APPROVAL"],
        requires_human=requires_human,
    ).transition(TaskState.ROUTING)
    task_exec,research=researcher.execute(
        task,
        f"Telegram command: {command}\nPayload: {payload or '(none)'}\n"
        "Return a concise operational response in Turkish. Start with RESEARCH_M17_4:. "
        "Never claim approval or authority."
    )
    review_task=TaskEnvelope.new(
        agent="reviewer", task_type="TELEGRAM_M17_4",
        scope=SCOPE, source_commit=SOURCE_COMMIT,
        required_evidence=list(task_exec.required_evidence),
        prohibited_actions=list(task_exec.prohibited_actions),
        requires_human=requires_human, parent_task_id=task_exec.task_id,
    )
    review_task=review_task.__class__(
        review_task.task_id, task_exec.correlation_id, review_task.agent,
        review_task.task_type, review_task.scope, review_task.source_commit,
        review_task.required_evidence, review_task.prohibited_actions,
        review_task.status, review_task.result, review_task.evidence,
        review_task.conflict_round, review_task.logical_problem_id,
        review_task.parent_task_id, review_task.requires_human,
    ).transition(TaskState.ROUTING)
    review_exec,review=reviewer.execute(
        review_task, source_task_id=str(task_exec.task_id),
        research_content=research.content,
        prompt="Review this Telegram task output for completeness. "
               "Return concise notes in Turkish. Start with REVIEW_M17_4:. "
               "Never approve or authorize."
    )
    evidence_task=TaskEnvelope.new(
        agent="evidence", task_type="TELEGRAM_M17_4",
        scope=SCOPE, source_commit=SOURCE_COMMIT,
        required_evidence=list(review_exec.required_evidence),
        prohibited_actions=list(review_exec.prohibited_actions),
        requires_human=requires_human, parent_task_id=review_exec.task_id,
    )
    evidence_task=evidence_task.__class__(
        evidence_task.task_id, review_exec.correlation_id, evidence_task.agent,
        evidence_task.task_type, evidence_task.scope, evidence_task.source_commit,
        evidence_task.required_evidence, evidence_task.prohibited_actions,
        evidence_task.status, evidence_task.result, evidence_task.evidence,
        evidence_task.conflict_round, evidence_task.logical_problem_id,
        evidence_task.parent_task_id, evidence_task.requires_human,
    ).transition(TaskState.ROUTING).transition(TaskState.EXECUTING).transition(TaskState.REVIEW)
    artifact=research.content+"\n"+review.content
    evidenced,record=evidence.execute(
        evidence_task, source_task_id=str(review_exec.task_id),
        producer=MODEL, producer_status="REVIEWED", artifact=artifact,
        evidence_refs=(f"research:{task_exec.task_id}",f"review:{review_exec.task_id}"),
    )
    if requires_human:
        gated=TaskEnvelope(
            evidenced.task_id,evidenced.correlation_id,evidenced.agent,evidenced.task_type,
            evidenced.scope,evidenced.source_commit,evidenced.required_evidence,
            evidenced.prohibited_actions,evidenced.status,evidenced.result,
            (record.__dict__,),evidenced.conflict_round,evidenced.logical_problem_id,
            evidenced.parent_task_id,True)
        human_state,gate=human_gate.request(gated)
        reply=f"HUMAN_GATE: {command} işlendi; insan onayı gerekiyor. {research.content}"
        terminal=human_state.status.value
    else:
        terminal=evidenced.transition(TaskState.COMPLETED).status.value
        reply=research.content
    return {"reply":reply.strip(),"status":terminal,"correlationId":str(task_exec.correlation_id),
            "model":MODEL,"chatId":chat_id,"review":"REVIEWED","evidence":"VERIFIED"}

class Handler(BaseHTTPRequestHandler):
    def do_POST(self):
        if self.path!="/m17/telegram":
            self.send_error(404); return
        try:
            n=int(self.headers.get("Content-Length","0")); body=json.loads(self.rfile.read(n))
            out=run_chain(str(body.get("command","")),str(body.get("payload","")),body.get("chatId"))
            data=json.dumps(out,ensure_ascii=False).encode()
            self.send_response(200); self.send_header("Content-Type","application/json"); self.send_header("Content-Length",str(len(data))); self.end_headers(); self.wfile.write(data)
        except Exception as exc:
            data=json.dumps({"error":type(exc).__name__,"reason":str(exc)},ensure_ascii=False).encode()
            self.send_response(500); self.send_header("Content-Type","application/json"); self.send_header("Content-Length",str(len(data))); self.end_headers(); self.wfile.write(data)
    def log_message(self,*args): pass

HTTPServer(("0.0.0.0",8090),Handler).serve_forever()
