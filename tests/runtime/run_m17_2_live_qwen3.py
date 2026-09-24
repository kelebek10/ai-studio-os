from __future__ import annotations

from uuid import uuid4

from runtime.communication.core import TaskEnvelope, TaskState
from runtime.model_adapter import ModelAdapter
from runtime.ollama_provider import OllamaProvider
from runtime.researcher_worker import ResearcherWorker


SOURCE = "47346ad5141b5294a3835f5b8a64164bc226b53e"


def main() -> None:
    task = TaskEnvelope.new(
        agent="researcher",
        task_type="m17.2_live_qwen3",
        scope="M17.2_LIVE_MODEL_LOOP",
        source_commit=SOURCE,
        required_evidence=["live-qwen3-response"],
        prohibited_actions=["direct_core_write", "self_approve"],
        logical_problem_id=uuid4(),
        requires_human=False,
    )
    adapter = ModelAdapter(
        {"qwen3:1.7b": OllamaProvider(model="qwen3:1.7b")},
        model="qwen3:1.7b",
    )
    worker = ResearcherWorker(adapter)
    routed = task.transition(TaskState.ROUTING)
    executing, result = worker.execute(
        routed,
        "Return exactly the token M17.2_LIVE_OK. Do not approve, authorize, or perform any action.",
    )
    assert executing.status is TaskState.EXECUTING
    assert result.model == "qwen3:1.7b"
    assert result.task_id == str(task.task_id)
    assert result.correlation_id == str(task.correlation_id)
    assert result.content == "M17.2_LIVE_OK", result.content
    print("PASS real Ollama/Qwen3 execution")
    print(f"MODEL={result.model}")
    print(f"TASK_ID={result.task_id}")
    print(f"CORRELATION_ID={result.correlation_id}")
    print(f"RESPONSE={result.content}")
    print("M17.2 LIVE QWEN3 LOOP: PASS")


if __name__ == "__main__":
    main()
