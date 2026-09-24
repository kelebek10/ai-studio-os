from runtime.agent_registry import AgentDefinition, AgentStatus, AgentTier
from runtime.communication.core import TaskEnvelope, TaskState
from runtime.model_adapter import ModelAdapter
from runtime.ollama_provider import OllamaProvider
from runtime.orchestrator import Orchestrator
from runtime.orchestrator_pipeline import OrchestratorPipeline
from runtime.provider_contract import Provider

class Registry:
    def get(self, agent_id):
        if agent_id == 'specialist:qwen:m18-2':
            return AgentDefinition(
                agent_id=agent_id, name='M18.2 Qwen Specialist', tier=AgentTier.SPECIALIST,
                scope='TASK_SCOPED', provider='QWEN', parent_agent_id='core:m18',
                status=AgentStatus.ACTIVE, approval_id=None,
            )
        return None

registry = Registry()
adapter = ModelAdapter({'qwen3:1.7b': OllamaProvider(base_url='http://127.0.0.1:11434', model='qwen3:1.7b', timeout=90)}, model='qwen3:1.7b')
task = TaskEnvelope.new(
    agent='specialist:qwen:m18-2', task_type='M18_2_LIVE_E2E', scope='TASK_SCOPED',
    source_commit='87978dd', required_evidence=['provider-output','review-output'],
    prohibited_actions=['APPROVE','PROVISION'], requires_human=True,
)
result = OrchestratorPipeline(Orchestrator(registry), adapter).run(
    task, Provider.QWEN,
    'Return a concise factual test acknowledgement. Do not claim approval, authority, or system changes.'
)
assert result.status is TaskState.HUMAN_GATE
assert result.review.verdict == 'REVIEWED'
assert result.evidence.evidence_digest
assert result.human_gate.human_action_required is True
print('M18.2 LIVE QWEN -> REVIEW -> EVIDENCE -> HUMAN_GATE: PASS')
print('MODEL:', result.review.model)
print('STATUS:', result.status.value)
print('EVIDENCE_DIGEST:', result.evidence.evidence_digest)
print('CORRELATION_ID:', result.human_gate.correlation_id)
