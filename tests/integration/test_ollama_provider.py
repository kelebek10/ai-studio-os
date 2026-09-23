from runtime.model_adapter import ModelAdapter
from runtime.ollama_provider import OllamaProvider
from runtime.communication import TaskState, create_task

def test_ollama_provider_health_and_live_qwen3():
    provider=OllamaProvider()
    assert provider.health() is True
    task=create_task(agent="qwen3",task_type="TEST",scope="m16.4",source_commit="b23fa00",required_evidence=["model_response"],prohibited_actions=["free_chat"])
    routed=task.transition(TaskState.ROUTING)
    response=ModelAdapter({"qwen3:1.7b":provider},model="qwen3:1.7b").execute(routed,"Reply with exactly: PAI-FORGE M16.4 LIVE PASS")
    assert response.model=="qwen3:1.7b"
    assert "PAI-FORGE M16.4 LIVE PASS" in response.content
