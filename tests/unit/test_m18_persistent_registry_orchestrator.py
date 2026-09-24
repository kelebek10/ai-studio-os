from runtime.agent_registry import AgentDefinition, AgentStatus, AgentTier
from runtime.communication.core import TaskEnvelope, TaskState
from runtime.model_adapter import FakeProvider, ModelAdapter
from runtime.orchestrator import Orchestrator
from runtime.provider_contract import Provider
from runtime.persistent_agent_registry import PersistentAgentRegistry

class Cursor:
    def __init__(self, rows): self.rows = rows
    def fetchone(self): return self.rows[0] if self.rows else None
    def fetchall(self): return self.rows

class Conn:
    def __init__(self):
        self.agent = AgentDefinition('specialist:qwen:test','Qwen Specialist',AgentTier.SPECIALIST,'TASK_SCOPED','QWEN','core:m18')
    def execute(self, query, params=()):
        if 'WHERE agent_id=%s' in query:
            a=self.agent
            return Cursor([(a.agent_id,a.name,a.tier.value,a.scope,a.provider,a.parent_agent_id,a.status.value,a.approval_id)])
        raise AssertionError(f'Unexpected query: {query}')

conn=Conn()
registry=PersistentAgentRegistry(conn)
agent=registry.get('specialist:qwen:test')
assert agent and agent.provider == 'QWEN'
task=TaskEnvelope.new(agent=agent.agent_id, task_type='M18_RUNTIME_INTEGRATION', scope='TASK_SCOPED', source_commit='dce198b', required_evidence=['registry'], prohibited_actions=['APPROVE'])
adapter=ModelAdapter({'fake': FakeProvider('INTEGRATION_TEST_RESPONSE')}, model='fake')
response=Orchestrator(registry).execute_provider_task(task, Provider.QWEN, adapter, 'integration test')
assert response.content == 'INTEGRATION_TEST_RESPONSE'
assert task.status is TaskState.VALIDATED
print('M18_PERSISTENT_REGISTRY_ORCHESTRATOR_INTEGRATION: PASS')
