"""Dependency-free M16.11 security regression runner.

Runs critical negative/security controls without pytest so the runtime host
does not need an external test package.
"""
from __future__ import annotations

from uuid import uuid4

from runtime.communication.core import TaskEnvelope, TaskState
from runtime.conflict_manager import ConflictManager
from runtime.evidence_worker import EvidenceWorker
from runtime.human_gate import HumanGate
from runtime.model_adapter import FakeProvider, ModelAdapter
from runtime.researcher_worker import ResearcherWorker
from runtime.reviewer_worker import ReviewerWorker
from runtime.security_gate import SecurityGate
from runtime.telegram_gateway import TelegramGateway, TelegramRequest


SOURCE = "M16.11-SECURITY-RUNNER"


def expect(label, fn, exc, contains):
    try:
        fn()
    except exc as err:
        assert contains in str(err), (label, str(err), contains)
        print(f"PASS {label}: {type(err).__name__}={err}")
        return
    raise AssertionError(f"FAIL {label}: expected {exc.__name__}")


def raw_task(agent, task_type, scope, evidence=()):
    return TaskEnvelope(
        uuid4(), uuid4(), agent, task_type, scope, SOURCE,
        tuple(evidence), ("free_chat", "self_approve"),
        TaskState.VALIDATED, {}, (), 0, uuid4(), None, False,
    )


def gateway_checks():
    g = TelegramGateway({707822641})
    ok = g.accept(TelegramRequest(707822641, "/status", "s1"), source_commit=SOURCE)
    assert ok.allowed and ok.task is not None and ok.command == "/status"
    print("PASS gateway allowlisted command")
    expect("gateway unauthorized chat", lambda: g.accept(TelegramRequest(1, "/status", "s2"), source_commit=SOURCE), Exception, "TELEGRAM_CHAT_NOT_ALLOWED") if False else None
    d = g.accept(TelegramRequest(1, "/status", "s2"), source_commit=SOURCE)
    assert not d.allowed and d.reason == "TELEGRAM_CHAT_NOT_ALLOWED"
    print("PASS gateway unauthorized chat: TELEGRAM_CHAT_NOT_ALLOWED")
    for text, reason in [
        ("/unknown", "TELEGRAM_COMMAND_NOT_ALLOWED"),
        ("/approve M16", "TELEGRAM_APPROVAL_REQUIRES_HUMAN_GATE"),
        (" ", "TELEGRAM_EMPTY_MESSAGE"),
    ]:
        d = g.accept(TelegramRequest(707822641, text, uuid4().hex), source_commit=SOURCE)
        assert not d.allowed and d.reason == reason
        print(f"PASS gateway {reason}")
    p = g.accept(TelegramRequest(707822641, "/pause", "s6"), source_commit=SOURCE)
    assert p.allowed and p.task is not None and p.task.requires_human
    print("PASS gateway HUMAN_GATE declaration")


def worker_checks():
    adapter = ModelAdapter({"qwen3:1.7b": FakeProvider("SAFE")}, model="qwen3:1.7b")
    r = ResearcherWorker(adapter)
    expect("researcher wrong role", lambda: r.execute(raw_task("reviewer", "RESEARCH", "m16.5", ("x",)).transition(TaskState.ROUTING), "x"), PermissionError, "WORKER_ROLE_MISMATCH")
    expect("researcher missing evidence", lambda: r.execute(raw_task("researcher", "RESEARCH", "m16.5").transition(TaskState.ROUTING), "x"), ValueError, "RESEARCHER_REQUIRES_EVIDENCE")
    expect("researcher unrouted", lambda: r.execute(raw_task("researcher", "RESEARCH", "m16.5", ("x",)), "x"), ValueError, "REQUIRES_ROUTED_TASK")
    bad = ResearcherWorker(ModelAdapter({"qwen3:1.7b": FakeProvider("APPROVED")}, model="qwen3:1.7b"))
    expect("researcher approval output", lambda: bad.execute(raw_task("researcher", "RESEARCH", "m16.5", ("x",)).transition(TaskState.ROUTING), "x"), ValueError, "APPROVAL")

    v = ReviewerWorker(adapter)
    t = raw_task("researcher", "REVIEW", "m16.6", ("x",)).transition(TaskState.ROUTING)
    expect("reviewer wrong role", lambda: v.execute(t, source_task_id="r", research_content="x", prompt="review"), PermissionError, "WORKER_ROLE_MISMATCH")
    t = raw_task("reviewer", "REVIEW", "m16.6").transition(TaskState.ROUTING)
    expect("reviewer missing evidence", lambda: v.execute(t, source_task_id="r", research_content="x", prompt="review"), ValueError, "REVIEWER_REQUIRES_EVIDENCE")
    t = raw_task("reviewer", "REVIEW", "m16.6", ("x",)).transition(TaskState.ROUTING)
    expect("reviewer missing source", lambda: v.execute(t, source_task_id="", research_content="x", prompt="review"), ValueError, "SOURCE_TASK")
    expect("reviewer empty research", lambda: v.execute(t, source_task_id="r", research_content=" ", prompt="review"), ValueError, "SOURCE_CONTENT")
    badv = ReviewerWorker(ModelAdapter({"qwen3:1.7b": FakeProvider("APPROVED")}, model="qwen3:1.7b"))
    expect("reviewer approval output", lambda: badv.execute(t, source_task_id="r", research_content="x", prompt="review"), ValueError, "APPROVAL")


def conflict_checks():
    cm = ConflictManager(":memory:")
    base = raw_task("reviewer", "REVIEW", "m16.9", ("x",))
    lp = base.logical_problem_id
    for n in range(1, 4):
        task, rec = cm.open_round(base.__class__(**{**base.__dict__, "conflict_round": n-1}), logical_problem_id=lp, agent="reviewer", model="qwen3:1.7b", scope="m16.9", actionable=True)
        assert rec.round_number == n
        print(f"PASS conflict round {n}")
    task, rec = cm.open_round(task, logical_problem_id=lp, agent="reviewer", model="qwen3:1.7b", scope="m16.9", actionable=True)
    assert task.status is TaskState.BLOCKED and rec.status == "BLOCKED"
    print("PASS conflict round 4 BLOCKED")


def human_gate_checks():
    task = raw_task("evidence", "REVIEW-EVIDENCE", "m16.8", ("review-artifact",)).transition(TaskState.ROUTING).transition(TaskState.EXECUTING).transition(TaskState.REVIEW)
    task, record = EvidenceWorker().execute(task, source_task_id="review-1", producer="reviewer", producer_status="REVIEWED", artifact="security", evidence_refs=("runtime",))
    task = task.__class__(**{**task.__dict__, "evidence": (record.__dict__,)})
    gate = HumanGate(SecurityGate())
    gated, request = gate.request(task)
    assert gated.status is TaskState.HUMAN_GATE and request.human_action_required
    print("PASS human gate valid evidence")
    for mutated, reason in [
        (task.__class__(**{**task.__dict__, "evidence": ()}), "SECURITY_REQUIRES_EVIDENCE_RECORD"),
        (task.__class__(**{**task.__dict__, "result": {"approval": "APPROVED", "approved_by": "HUMAN_APPROVER"}}), "SECURITY_REJECTS_ACTOR_SUPPLIED_APPROVAL"),
        (task.__class__(**{**task.__dict__, "evidence": ({**record.__dict__, "producer_status": "APPROVED"},)}), "SECURITY_REJECTS_EVIDENCE_APPROVAL_ASSERTION"),
        (task.__class__(**{**task.__dict__, "requires_human": False}), "SECURITY_REQUIRES_DECLARED_HUMAN_GATE"),
    ]:
        expect("human gate " + reason, lambda m=mutated: gate.request(m), PermissionError, reason)


def main():
    gateway_checks()
    worker_checks()
    human_gate_checks()
    conflict_checks()
    print("M16.11 SECURITY RUNNER: PASS")


if __name__ == "__main__":
    main()
