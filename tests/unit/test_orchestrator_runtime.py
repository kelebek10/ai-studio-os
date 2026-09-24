from runtime.agent_registry import HumanApproval, HUMAN
from runtime.communication.core import TaskEnvelope
from runtime.model_adapter import FakeProvider, ModelAdapter
from runtime.orchestrator import Orchestrator
from runtime.provider_contract import Authority, Provider


def test_orchestrator_runs_registered_provider_task_only():
    orch = Orchestrator()
    core = orch.registry.create_core("Research Core", "TASK_SCOPED", HumanApproval("H-1", HUMAN, "test"))
    specialist = orch.provision_specialist(name="Research", provider=Provider.QWEN, scope="TASK_SCOPED", parent_agent_id=core.agent_id)
    task = TaskEnvelope.new(
        agent=specialist.agent_id, task_type="RESEARCH", scope="TASK_SCOPED", source_commit="test",
        required_evidence=["model_response"], prohibited_actions=["APPROVE", "PROVISION"]
    )
    adapter = ModelAdapter({"qwen3:1.7b": FakeProvider("RUNTIME_OK")}, model="qwen3:1.7b")
    response = orch.execute_provider_task(task, Provider.QWEN, adapter, "test")
    assert response.content == "RUNTIME_OK"
    assert response.model == "qwen3:1.7b"


def test_orchestrator_rejects_provider_mismatch():
    orch = Orchestrator()
    core = orch.registry.create_core("Claude Core", "TASK_SCOPED", HumanApproval("H-2", HUMAN, "test"))
    specialist = orch.provision_specialist(name="Claude", provider=Provider.CLAUDE, scope="TASK_SCOPED", parent_agent_id=core.agent_id)
    task = TaskEnvelope.new(
        agent=specialist.agent_id, task_type="RESEARCH", scope="TASK_SCOPED", source_commit="test",
        required_evidence=["model_response"], prohibited_actions=["APPROVE"]
    )
    adapter = ModelAdapter({"qwen3:1.7b": FakeProvider("NO")}, model="qwen3:1.7b")
    try:
        orch.execute_provider_task(task, Provider.QWEN, adapter, "test")
    except PermissionError as exc:
        assert str(exc) == "AGENT_PROVIDER_MISMATCH"
    else:
        raise AssertionError("provider mismatch escaped")


def test_orchestrator_cannot_grant_approval_or_provision():
    orch = Orchestrator()
    core = orch.registry.create_core("Core", "TASK_SCOPED", HumanApproval("H-3", HUMAN, "test"))
    specialist = orch.provision_specialist(name="Qwen", provider=Provider.QWEN, scope="TASK_SCOPED", parent_agent_id=core.agent_id)
    task = TaskEnvelope.new(
        agent=specialist.agent_id, task_type="RESEARCH", scope="TASK_SCOPED", source_commit="test",
        required_evidence=["model_response"], prohibited_actions=["APPROVE"]
    )
    adapter = ModelAdapter({"qwen3:1.7b": FakeProvider("NO")}, model="qwen3:1.7b")
    for forbidden in (Authority.APPROVE, Authority.PROVISION):
        try:
            orch.assign_provider(task, Provider.QWEN, forbidden)
        except PermissionError:
            pass
        else:
            raise AssertionError(f"forbidden authority escaped: {forbidden}")
