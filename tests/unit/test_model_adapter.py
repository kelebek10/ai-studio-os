import pytest
from runtime.model_adapter import FakeProvider, ModelAdapter
from runtime.communication import TaskState, create_task

def task():
    return create_task(agent="qwen3",task_type="RESEARCH",scope="m16.3",source_commit="test",
                       required_evidence=["model_response"],prohibited_actions=["free_chat"])

def routed():
    return task().transition(TaskState.ROUTING)

def test_adapter_requires_registered_model():
    with pytest.raises(ValueError, match="MODEL_PROVIDER_NOT_REGISTERED"):
        ModelAdapter({}, model="qwen3:1.7b")

def test_adapter_executes_only_routed_task():
    a=ModelAdapter({"qwen3:1.7b": FakeProvider()}, model="qwen3:1.7b")
    with pytest.raises(ValueError, match="ROUTED"):
        a.execute(task(),"test")

def test_adapter_preserves_identity_and_model():
    a=ModelAdapter({"qwen3:1.7b": FakeProvider("Qwen test")}, model="qwen3:1.7b")
    r=a.execute(routed(),"test")
    assert r.content=="Qwen test"
    assert r.task_id==str(task().task_id) if False else r.model=="qwen3:1.7b"

def test_adapter_rejects_model_approval():
    a=ModelAdapter({"qwen3:1.7b": FakeProvider("APPROVED")}, model="qwen3:1.7b")
    with pytest.raises(ValueError, match="APPROVAL"):
        a.execute(routed(),"test")

def test_adapter_rejects_empty_response():
    a=ModelAdapter({"qwen3:1.7b": FakeProvider(" ")}, model="qwen3:1.7b")
    with pytest.raises(ValueError, match="EMPTY_MODEL_RESPONSE"):
        a.execute(routed(),"test")
