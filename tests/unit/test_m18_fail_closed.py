from runtime.agent_registry import AgentRegistry, HumanApproval, HUMAN
from runtime.communication.core import TaskEnvelope, TaskState
from runtime.model_adapter import FakeProvider, ModelAdapter
from runtime.evidence_worker import EvidenceWorker
from runtime.human_gate import HumanGate
from runtime.orchestrator import Orchestrator
from runtime.orchestrator_pipeline import OrchestratorPipeline
from runtime.provider_contract import Authority, Provider


def make_task(requires_human=True):
    o=Orchestrator(AgentRegistry())
    c=o.registry.create_core('Core','TASK_SCOPED',HumanApproval('H','HUMAN','test'))
    s=o.provision_specialist(name='Qwen',provider=Provider.QWEN,scope='TASK_SCOPED',parent_agent_id=c.agent_id)
    t=TaskEnvelope.new(agent=s.agent_id,task_type='RESEARCH',scope='TASK_SCOPED',source_commit='test',required_evidence=['model'],prohibited_actions=['APPROVE','PROVISION'],requires_human=requires_human)
    return o,t

def test_model_approval_is_rejected():
    o,t=make_task(False)
    a=ModelAdapter({'qwen3:1.7b':FakeProvider('APPROVED')},model='qwen3:1.7b')
    try: o.execute_provider_task(t,Provider.QWEN,a,'test')
    except ValueError as e: assert 'APPROVAL' in str(e)
    else: raise AssertionError('model approval escaped')

def test_evidence_digest_mismatch_is_rejected():
    _,t=make_task(True)
    reviewed=t.transition(TaskState.ROUTING).transition(TaskState.EXECUTING).transition(TaskState.REVIEW)
    try: EvidenceWorker().execute(reviewed,source_task_id='source',producer='qwen',producer_status='REVIEWED',artifact='artifact',evidence_refs=('ref',),expected_artifact_digest='bad')
    except ValueError as e: assert str(e)=='ARTIFACT_DIGEST_MISMATCH'
    else: raise AssertionError('bad digest escaped')

def test_human_gate_fails_closed_without_evidence():
    _,t=make_task(True)
    evidenced=t.transition(TaskState.ROUTING).transition(TaskState.EXECUTING).transition(TaskState.REVIEW).transition(TaskState.EVIDENCE)
    try: HumanGate().request(evidenced)
    except PermissionError as e: assert str(e)=='SECURITY_REQUIRES_EVIDENCE_RECORD'
    else: raise AssertionError('missing evidence reached gate')

def test_provider_cannot_receive_approval_or_provision():
    o,t=make_task(True)
    for a in (Authority.APPROVE,Authority.PROVISION):
        try: o.assign_provider(t,Provider.QWEN,a)
        except PermissionError: pass
        else: raise AssertionError(a)

print('M18_FAIL_CLOSED_TESTS: PASS')
