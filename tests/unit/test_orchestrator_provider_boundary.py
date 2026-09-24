from runtime.agent_registry import AgentRegistry, HumanApproval, HUMAN
from runtime.communication.core import TaskEnvelope
from runtime.orchestrator import Orchestrator
from runtime.provider_contract import Authority, Provider


def task():
    return TaskEnvelope.new(
        agent="specialist:qwen:research",
        task_type="RESEARCH",
        scope="TASK_SCOPED",
        source_commit="test",
        required_evidence=["result"],
        prohibited_actions=["approve", "provision"],
    )


def run():
    orch = Orchestrator(AgentRegistry())
    t = task()
    assignment = orch.assign_provider(t, Provider.QWEN)
    assert assignment.provider is Provider.QWEN
    assert assignment.authority is Authority.EXECUTE

    for forbidden in (Authority.APPROVE, Authority.PROVISION):
        try:
            orch.assign_provider(t, Provider.QWEN, forbidden)
        except PermissionError as exc:
            assert str(exc) == f"PROVIDER_AUTHORITY_DENIED:{forbidden.value}"
        else:
            raise AssertionError(f"provider authority escaped: {forbidden}")

    gate = orch.request_core_agent(name="Evidence Core", scope="EVIDENCE")
    assert gate.startswith("HUMAN_GATE:CREATE_CORE_AGENT:")

    core = orch.registry.create_core("Research Core", "RESEARCH", HumanApproval("A-1", HUMAN, "test"))
    specialist = orch.provision_specialist(name="Research", provider=Provider.GEMINI, scope="TASK_SCOPED", parent_agent_id=core.agent_id)
    assert specialist.parent_agent_id == core.agent_id

    try:
        orch.registry.create_specialist("Denied", "QWEN", "TASK_SCOPED", core.agent_id, created_by="QWEN")
    except PermissionError as exc:
        assert str(exc) == "ONLY_ORCHESTRATOR_MAY_CREATE_SPECIALIST"
    else:
        raise AssertionError("provider created specialist")

    print("ORCHESTRATOR_PROVIDER_BOUNDARY_TESTS: PASS")


if __name__ == "__main__":
    run()
