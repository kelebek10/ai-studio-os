from runtime.model_adapter import ModelAdapter
from runtime.ollama_provider import OllamaProvider
from runtime.communication import TaskState, create_task

def test_live_qwen3():
    p=OllamaProvider()
    assert p.health() is True
    t=create_task(agent="qwen3",task_type="TEST",scope="m16.4",source_commit="99e0653",required_evidence=["model_response"],prohibited_actions=["free_chat"])
    r=t.transition(TaskState.ROUTING)
    out=ModelAdapter({"qwen3:1.7b":p},model="qwen3:1.7b").execute(r,"Reply with exactly: PAI-FORGE M16.4 LIVE PASS")
    assert out.model=="qwen3:1.7b"
    assert "PAI-FORGE M16.4 LIVE PASS" in out.content
