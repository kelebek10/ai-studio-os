from __future__ import annotations

from runtime.communication.core import TaskEnvelope, TaskState
from runtime.evidence_worker import EvidenceWorker


def task(status: TaskState = TaskState.REVIEW) -> TaskEnvelope:
    t = TaskEnvelope.new(
        agent="evidence",
        task_type="evidence.verify",
        scope="m16.7",
        source_commit="8b15fd62ff689e73dfd6e1cf943f18c78be8c775",
        required_evidence=["artifact_digest", "evidence_digest", "evidence_refs"],
        prohibited_actions=["self_approval", "authority_creation"],
    )
    return t.transition(TaskState.ROUTING).transition(TaskState.EXECUTING).transition(TaskState.REVIEW) if status is TaskState.REVIEW else t


def run() -> None:
    worker = EvidenceWorker()
    base = task()
    artifact = "PAI-FORGE M16.7 evidence payload"

    evidenced, record = worker.execute(
        base,
        source_task_id="m16.6-live-reviewer",
        producer="reviewer",
        producer_status="REVIEWED",
        artifact=artifact,
        evidence_refs=["m16.6-live-reviewer", "commit:8b15fd6"],
    )
    assert evidenced.status is TaskState.EVIDENCE
    assert record.task_id == str(base.task_id)
    assert record.correlation_id == str(base.correlation_id)
    assert len(record.artifact_digest) == 64
    assert len(record.evidence_digest) == 64

    _, record2 = worker.execute(
        base,
        source_task_id="m16.6-live-reviewer",
        producer="reviewer",
        producer_status="REVIEWED",
        artifact=artifact,
        evidence_refs=["m16.6-live-reviewer", "commit:8b15fd6"],
        expected_artifact_digest=record.artifact_digest,
    )
    assert record2 == record

    checks = [
        ("role", lambda: worker.execute(task(), source_task_id="x", producer="reviewer", producer_status="REVIEWED", artifact=artifact, evidence_refs=["x"])),
        ("state", lambda: worker.execute(task(TaskState.ROUTING), source_task_id="x", producer="reviewer", producer_status="REVIEWED", artifact=artifact, evidence_refs=["x"])),
        ("approval", lambda: worker.execute(base, source_task_id="x", producer="reviewer", producer_status="APPROVED", artifact=artifact, evidence_refs=["x"])),
        ("digest", lambda: worker.execute(base, source_task_id="x", producer="reviewer", producer_status="REVIEWED", artifact=artifact, evidence_refs=["x"], expected_artifact_digest="0"*64)),
        ("refs", lambda: worker.execute(base, source_task_id="x", producer="reviewer", producer_status="REVIEWED", artifact=artifact, evidence_refs=[])),
    ]
    # Role check uses a task with the wrong agent.
    wrong = TaskEnvelope.new(
        agent="reviewer", task_type="evidence.verify", scope="m16.7",
        source_commit="8b15fd6", required_evidence=["x"], prohibited_actions=[]
    ).transition(TaskState.ROUTING).transition(TaskState.EXECUTING).transition(TaskState.REVIEW)
    try:
        worker.execute(wrong, source_task_id="x", producer="reviewer", producer_status="REVIEWED", artifact=artifact, evidence_refs=["x"])
    except PermissionError as exc:
        assert str(exc) == "WORKER_ROLE_MISMATCH"
    else:
        raise AssertionError("role control did not block")

    for name, fn in checks[1:]:
        try:
            fn()
        except (ValueError, PermissionError):
            pass
        else:
            raise AssertionError(f"{name} control did not block")

    print("M16.7 UNIT HARNESS: PASS")
    print(f"ARTIFACT_DIGEST={record.artifact_digest}")
    print(f"EVIDENCE_DIGEST={record.evidence_digest}")


if __name__ == "__main__":
    run()
