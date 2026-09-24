from __future__ import annotations
from uuid import uuid4

from runtime.communication.core import TaskEnvelope, TaskState
from runtime.communication.router import OrchestratorRouter
from runtime.communication.dispatch import ControlledDispatcher
from runtime.model_adapter import FakeProvider, ModelAdapter
from runtime.researcher_worker import ResearcherWorker
from runtime.reviewer_worker import ReviewerWorker
from runtime.evidence_worker import EvidenceWorker
from runtime.security_gate import SecurityGate
from runtime.human_gate import HumanGate


SOURCE = "90efa6725108932414501d0b0573285623e0b317"

def clone(task, **changes):
    data = dict(task.__dict__)
    data.update(changes)
    return task.__class__(**data)

def make_task(agent, problem, *, requires_human=False):
    return TaskEnvelope.new(
        agent=agent,
        task_type="m17.1_mission",
        scope="M17.1_CONTROLLED_RUNTIME_LOOP",
        source_commit=SOURCE,
        required_evidence=["mission-evidence"],
        prohibited_actions=["direct_core_write", "self_approve"],
        logical_problem_id=problem,
        requires_human=requires_human,
    )

def expect_failure(label, fn, expected):
    try:
        fn()
    except Exception as exc:
        assert expected in str(exc), (label, exc)
        print(f"PASS {label}: {type(exc).__name__}={exc}")
        return
    raise AssertionError(f"FAIL {label}: expected {expected}")

def main():
    problem = uuid4()
    provider = FakeProvider("M17_CONTROLLED_RESPONSE")
    adapter = ModelAdapter({"qwen3-test": provider}, model="qwen3-test")
    router = OrchestratorRouter({"researcher": "RESEARCHER", "reviewer": "REVIEWER", "evidence": "EVIDENCE"})
    researcher = ResearcherWorker(adapter)
    reviewer = ReviewerWorker(adapter)
    evidence = EvidenceWorker()
    security = SecurityGate()
    human_gate = HumanGate(security)

    task = make_task("researcher", problem, requires_human=True)
    assert task.status is TaskState.VALIDATED
    routed, route = router.route(task)
    assert routed.status is TaskState.ROUTING
    print("PASS VALIDATED -> ROUTING")

    executing, research = researcher.execute(routed, "Produce a bounded research result.")
    assert executing.status is TaskState.EXECUTING
    reviewed_state = executing.transition(TaskState.REVIEW)
    print("PASS ROUTING -> EXECUTING -> REVIEW")
    review_task = make_task("reviewer", problem, requires_human=True)
    review_task = clone(
        review_task,
        correlation_id=task.correlation_id,
        parent_task_id=executing.task_id,
        status=TaskState.ROUTING,
    )
    review_executing, review = reviewer.execute(
        review_task,
        source_task_id=str(research.task_id),
        research_content=research.content,
        prompt="Review the supplied research for evidence readiness.",
    )
    review_ready = review_executing.transition(TaskState.REVIEW)
    evidence_task = make_task("evidence", problem, requires_human=True)
    evidence_task = clone(
        evidence_task,
        correlation_id=task.correlation_id,
        parent_task_id=review_executing.task_id,
        status=TaskState.REVIEW,
    )
    evidenced, record = evidence.execute(
        evidence_task,
        source_task_id=str(review.task_id),
        producer="reviewer",
        producer_status=review.verdict,
        artifact=review.content,
        evidence_refs=["m17.1:review", "m17.1:research"],
    )
    evidenced = clone(
        evidenced,
        evidence=(record.__dict__,),
        result={"mission": "M17.1"},
    )
    assert evidenced.status is TaskState.EVIDENCE
    assert record.correlation_id == str(task.correlation_id)
    completed = evidenced.transition(TaskState.COMPLETED)
    assert completed.status is TaskState.COMPLETED
    print("PASS REVIEW -> EVIDENCE -> COMPLETED with lineage")

    dispatcher = ControlledDispatcher()
    calls = {"count": 0}
    def handler(_task):
        calls["count"] += 1
        return {"mission": "M17.1"}
    dispatcher.register("researcher", handler)
    _, first = dispatcher.dispatch(task)
    _, second = dispatcher.dispatch(task)
    assert first is second and calls["count"] == 1
    print("PASS duplicate delivery is idempotent")

    decision = security.inspect(evidenced)
    assert decision.allowed
    gated, request = human_gate.request(evidenced)
    assert gated.status is TaskState.HUMAN_GATE
    print("PASS SECURITY -> HUMAN_GATE request")
    print(f"EVIDENCE_DIGEST={record.evidence_digest}")
    print(f"TASK_ID={task.task_id}")
    print(f"CORRELATION_ID={task.correlation_id}")
    # Negative controls.
    expect_failure(
        "invalid transition",
        lambda: task.transition(TaskState.COMPLETED),
        "INVALID_TRANSITION",
    )
    expect_failure(
        "unauthorized route",
        lambda: OrchestratorRouter({"researcher": "CORE"}).route(task),
        "ROUTER_CANNOT_ROUTE_TO_AUTHORITY_OR_CORE",
    )
    expect_failure(
        "model approval assertion",
        lambda: ModelAdapter({"bad": FakeProvider("APPROVED")}, model="bad").execute(
            routed, "test"
        ),
        "MODEL_CANNOT_ASSERT_APPROVAL",
    )
    missing_evidence = clone(evidenced, evidence=())
    decision = security.inspect(missing_evidence)
    assert not decision.allowed
    assert decision.reason == "SECURITY_REQUIRES_EVIDENCE_RECORD"
    print(f"PASS missing evidence: {decision.reason}")
    conflict_task = task.next_conflict_round().next_conflict_round().next_conflict_round()
    blocked = conflict_task.next_conflict_round()
    assert blocked.status is TaskState.BLOCKED
    assert blocked.conflict_round == 4
    print("PASS conflict round 4: BLOCKED")
    expect_failure(
        "undeclared human gate",
        lambda: HumanGate().request(clone(evidenced, requires_human=False)),
        "SECURITY_REQUIRES_DECLARED_HUMAN_GATE",
    )

    print("M17.1 CONTROLLED RUNTIME LOOP: PASS")

if __name__ == "__main__":
    main()
