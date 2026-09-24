from dataclasses import dataclass
from .communication.core import TaskEnvelope, TaskState
from .evidence_worker import EvidenceWorker
from .human_gate import HumanGate
from .model_adapter import ModelAdapter
from .orchestrator import Orchestrator
from .provider_contract import Provider
from .reviewer_worker import ReviewerWorker
from .security_gate import SecurityGate

@dataclass(frozen=True)
class PipelineResult:
    status: TaskState
    review: object
    evidence: object
    human_gate: object

class OrchestratorPipeline:
    def __init__(self, orchestrator: Orchestrator, adapter: ModelAdapter):
        self.orchestrator = orchestrator
        self.reviewer = ReviewerWorker(adapter)
        self.evidence = EvidenceWorker()
        self.human_gate = HumanGate(SecurityGate())
        self.adapter = adapter

    def run(self, task: TaskEnvelope, provider: Provider, prompt: str) -> PipelineResult:
        response = self.orchestrator.execute_provider_task(task, provider, self.adapter, prompt)
        review_task = TaskEnvelope.new(agent="reviewer", task_type="M18_REVIEW", scope=task.scope, source_commit=task.source_commit, required_evidence=list(task.required_evidence), prohibited_actions=list(task.prohibited_actions), requires_human=task.requires_human, parent_task_id=task.task_id).transition(TaskState.ROUTING)
        review_task = review_task.__class__(review_task.task_id, response.correlation_id, review_task.agent, review_task.task_type, review_task.scope, review_task.source_commit, review_task.required_evidence, review_task.prohibited_actions, review_task.status, review_task.result, review_task.evidence, review_task.conflict_round, review_task.logical_problem_id, review_task.parent_task_id, review_task.requires_human)
        reviewed, review = self.reviewer.execute(review_task, source_task_id=str(task.task_id), research_content=response.content, prompt="Review provider output. Never approve.")
        evidence_task = TaskEnvelope.new(agent="evidence", task_type="M18_EVIDENCE", scope=task.scope, source_commit=task.source_commit, required_evidence=list(task.required_evidence), prohibited_actions=list(task.prohibited_actions), requires_human=task.requires_human, parent_task_id=reviewed.task_id).transition(TaskState.ROUTING).transition(TaskState.EXECUTING).transition(TaskState.REVIEW)
        evidenced, record = self.evidence.execute(evidence_task, source_task_id=str(reviewed.task_id), producer=review.model, producer_status=review.verdict, artifact=response.content+"\n"+review.content, evidence_refs=(f"provider:{task.task_id}", f"review:{reviewed.task_id}"))
        evidence_task = evidenced.__class__(evidenced.task_id, evidenced.correlation_id, evidenced.agent, evidenced.task_type, evidenced.scope, evidenced.source_commit, evidenced.required_evidence, evidenced.prohibited_actions, evidenced.status, evidenced.result, (record.__dict__,), evidenced.conflict_round, evidenced.logical_problem_id, evidenced.parent_task_id, evidenced.requires_human)
        if task.requires_human:
            gated, gate = self.human_gate.request(evidence_task)
            return PipelineResult(gated.status, review, record, gate)
        return PipelineResult(evidence_task.transition(TaskState.COMPLETED).status, review, record, None)
