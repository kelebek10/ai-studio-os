import pytest
from runtime.communication import TaskState, create_task
from runtime.communication.router import OrchestratorRouter

def task(agent="researcher"):
    return create_task(agent=agent, task_type="RESEARCH", scope="m16.2", source_commit="test",
                       required_evidence=["result"], prohibited_actions=["free_chat"])

def test_router_routes_only_validated_task():
    routed, ack = OrchestratorRouter({"researcher": "RESEARCHER"}).route(task())
    assert routed.status is TaskState.ROUTING
    assert ack.target == "RESEARCHER"

def test_router_denies_unknown_target():
    with pytest.raises(PermissionError, match="UNAUTHORIZED"):
        OrchestratorRouter({"reviewer": "REVIEWER"}).route(task())

def test_router_does_not_route_to_authority_or_core():
    with pytest.raises(PermissionError, match="AUTHORITY_OR_CORE"):
        OrchestratorRouter({"researcher": "CORE"}).route(task())

def test_router_cannot_route_twice_without_new_control_transition():
    router = OrchestratorRouter({"researcher": "RESEARCHER"})
    routed, _ = router.route(task())
    with pytest.raises(ValueError, match="VALIDATED"):
        router.route(routed)
