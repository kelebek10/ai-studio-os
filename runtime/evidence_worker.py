from __future__ import annotations

from dataclasses import dataclass
import hashlib
import json

from .communication.core import TaskEnvelope, TaskState


@dataclass(frozen=True)
class EvidenceRecord:
    task_id: str
    correlation_id: str
    scope: str
    source_commit: str
    source_task_id: str
    producer: str
    producer_status: str
    artifact_digest: str
    evidence_digest: str
    evidence_refs: tuple[str, ...]


class EvidenceWorker:
    """Deterministic provenance/integrity worker. It verifies evidence; it never decides truth or authority."""

    def execute(
        self,
        task: TaskEnvelope,
        *,
        source_task_id: str,
        producer: str,
        producer_status: str,
        artifact: str,
        evidence_refs: tuple[str, ...] | list[str],
        expected_artifact_digest: str | None = None,
    ) -> tuple[TaskEnvelope, EvidenceRecord]:
        if task.agent != "evidence":
            raise PermissionError("WORKER_ROLE_MISMATCH")
        if task.status is not TaskState.REVIEW:
            raise ValueError("EVIDENCE_REQUIRES_REVIEW_STATE")
        if not source_task_id:
            raise ValueError("EVIDENCE_REQUIRES_SOURCE_TASK")
        if not producer:
            raise ValueError("EVIDENCE_REQUIRES_PRODUCER")
        if not producer_status:
            raise ValueError("EVIDENCE_REQUIRES_PRODUCER_STATUS")
        if producer_status.upper() == "APPROVED":
            raise ValueError("EVIDENCE_CANNOT_ASSERT_APPROVAL")
        if not artifact:
            raise ValueError("EVIDENCE_REQUIRES_ARTIFACT")
        refs = tuple(evidence_refs)
        if not refs or any(not ref.strip() for ref in refs):
            raise ValueError("EVIDENCE_REQUIRES_REFERENCES")

        artifact_digest = hashlib.sha256(artifact.encode("utf-8")).hexdigest()
        if expected_artifact_digest is not None and expected_artifact_digest != artifact_digest:
            raise ValueError("ARTIFACT_DIGEST_MISMATCH")

        canonical = json.dumps(
            {
                "artifact_digest": artifact_digest,
                "correlation_id": str(task.correlation_id),
                "producer": producer,
                "producer_status": producer_status,
                "scope": task.scope,
                "source_commit": task.source_commit,
                "source_task_id": source_task_id,
                "evidence_refs": list(refs),
            },
            sort_keys=True,
            separators=(",", ":"),
            ensure_ascii=False,
        )
        evidence_digest = hashlib.sha256(canonical.encode("utf-8")).hexdigest()
        evidenced = task.transition(TaskState.EVIDENCE)
        return evidenced, EvidenceRecord(
            task_id=str(evidenced.task_id),
            correlation_id=str(evidenced.correlation_id),
            scope=evidenced.scope,
            source_commit=evidenced.source_commit,
            source_task_id=source_task_id,
            producer=producer,
            producer_status=producer_status,
            artifact_digest=artifact_digest,
            evidence_digest=evidence_digest,
            evidence_refs=refs,
        )
