from runtime.communication.core import TaskEnvelope, TaskState
from runtime.evidence_worker import EvidenceWorker
from runtime.human_gate import HumanGate
from runtime.security_gate import SecurityGate

SOURCE = "7222fa7e620672329ac99f41e07b8efc7db1c892"

def base_task():
    return TaskEnvelope.new(
        agent="evidence", task_type="review-evidence", scope="M16.8", source_commit=SOURCE,
        required_evidence=["review-artifact"], prohibited_actions=["self-approve"],
        requires_human=True,
    ).transition(TaskState.ROUTING).transition(TaskState.EXECUTING).transition(TaskState.REVIEW)

def evidenced():
    task, record = EvidenceWorker().execute(
        base_task(), source_task_id="review-1", producer="reviewer", producer_status="REVIEWED",
        artifact="PAI-FORGE M16.8 SECURITY TEST ARTIFACT", evidence_refs=("runtime-test",),
    )
    return task, record

def main():
    task, record = evidenced()
    task = task.__class__(**{**task.__dict__, "evidence": (record.__dict__,)})
    gate = HumanGate(SecurityGate())
    gated, request = gate.request(task)
    assert gated.status is TaskState.HUMAN_GATE
    assert request.human_action_required is True

    # Missing evidence cannot clear the gate.
    no_evidence = task.__class__(**{**task.__dict__, "evidence": ()})
    try:
        gate.request(no_evidence)
        raise AssertionError("missing evidence was accepted")
    except PermissionError as exc:
        assert str(exc) == "SECURITY_REQUIRES_EVIDENCE_RECORD"

    # AI/textual approval cannot clear the gate.
    spoof = task.__class__(**{**task.__dict__, "result": {"approval": "APPROVED", "approved_by": "HUMAN_APPROVER"}})
    try:
        gate.request(spoof)
        raise AssertionError("approval spoof was accepted")
    except PermissionError as exc:
        assert str(exc) == "SECURITY_REJECTS_ACTOR_SUPPLIED_APPROVAL"

    # Evidence producer cannot assert human approval.
    bad = task.__class__(**{**task.__dict__, "evidence": ({**record.__dict__, "producer_status": "APPROVED"},)})
    try:
        gate.request(bad)
        raise AssertionError("approved evidence was accepted")
    except PermissionError as exc:
        assert str(exc) == "SECURITY_REJECTS_EVIDENCE_APPROVAL_ASSERTION"

    # No human declaration => no gate.
    no_human = task.__class__(**{**task.__dict__, "requires_human": False})
    try:
        gate.request(no_human)
        raise AssertionError("undeclared human gate was accepted")
    except PermissionError as exc:
        assert str(exc) == "SECURITY_REQUIRES_DECLARED_HUMAN_GATE"

    print("M16.8 HUMAN GATE SECURITY HARNESS: PASS")

if __name__ == "__main__":
    main()
