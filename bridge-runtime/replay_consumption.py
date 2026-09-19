"""
COMM-BRIDGE-IMPLEMENT-04 — P1-2: replay/idempotency acceptance +
consumption ordering.

HONESTY NOTE: same class as round_lineage.py — this is a Python MODEL
of the real SQL contract already specified in
governance/BRIDGE-RUNTIME-V1-PREREQUISITES-v1.0.md section 5:
UNIQUE(logical_problem_id, artifact_digest), and "consumed" only after
the INSERT commits. The lock in ResultLedger models a single Postgres
UNIQUE-constrained INSERT's atomicity; it does NOT prove real Postgres
concurrent-transaction behavior, multi-host races, or restart recovery
against a real database (P1-2 runtime criterion remains
BLOCKED / CAPABILITY GAP — no reachable Postgres in this environment).
"""
from __future__ import annotations
import json
import threading
from dataclasses import dataclass


@dataclass(frozen=True)
class ResultSubmission:
    task_id: str
    logical_problem_id: str
    artifact_digest: str
    correlation_id: str


class DuplicateResultRejected(Exception):
    """Raised when a submission's (logical_problem_id, artifact_digest)
    pair has already been accepted — this IS a replay by the corrected
    P1-2 definition, even if task_id differs."""


class ResultLedger:
    """Idempotency key is (logical_problem_id, artifact_digest) —
    deliberately NOT (task_id, correlation_id, artifact_digest), per the
    P1-2 correction in COMM-BRIDGE-IMPLEMENT-03: a different task_id
    carrying the same logical_problem_id + artifact_digest is the same
    logical result and MUST be treated as a replay."""

    def __init__(self) -> None:
        self._accepted: dict[tuple[str, str], ResultSubmission] = {}
        self._lock = threading.Lock()

    def submit(self, submission: ResultSubmission) -> ResultSubmission:
        """Atomic (within this process) accept-or-reject. Only the
        winner of the lock for a given key is accepted; all others,
        including ones with a different task_id but the same
        (logical_problem_id, artifact_digest), are rejected as
        duplicates. Mirrors an `INSERT ... ON CONFLICT DO NOTHING`
        followed by checking whether the row is "ours"."""
        key = (submission.logical_problem_id, submission.artifact_digest)
        with self._lock:
            if key in self._accepted:
                raise DuplicateResultRejected(
                    f"replay: logical_problem_id={submission.logical_problem_id} "
                    f"artifact_digest={submission.artifact_digest} "
                    f"already accepted via task_id={self._accepted[key].task_id}"
                )
            self._accepted[key] = submission
            return submission

    def is_consumed(self, logical_problem_id: str, artifact_digest: str) -> bool:
        with self._lock:
            return (logical_problem_id, artifact_digest) in self._accepted

    # ---- restart-persistence MODEL (see HONESTY NOTE in round_lineage.py) ----

    def to_json(self) -> str:
        with self._lock:
            return json.dumps([
                {"task_id": s.task_id, "logical_problem_id": s.logical_problem_id,
                 "artifact_digest": s.artifact_digest, "correlation_id": s.correlation_id}
                for s in self._accepted.values()
            ])

    @classmethod
    def from_json(cls, blob: str) -> "ResultLedger":
        ledger = cls()
        for row in json.loads(blob):
            submission = ResultSubmission(**row)
            key = (submission.logical_problem_id, submission.artifact_digest)
            ledger._accepted[key] = submission
        return ledger


def concurrent_duplicate_submission_only_one_wins(ledger: ResultLedger,
                                                   submissions: list[ResultSubmission]) -> int:
    """Fires len(submissions) submissions concurrently (real OS threads)
    that all share the same (logical_problem_id, artifact_digest).
    Returns the count that were accepted — correct behavior is exactly
    1, regardless of how many threads race."""
    accepted_count = 0
    count_lock = threading.Lock()
    errors: list[Exception] = []

    def worker(sub: ResultSubmission) -> None:
        nonlocal accepted_count
        try:
            ledger.submit(sub)
            with count_lock:
                accepted_count += 1
        except DuplicateResultRejected as exc:
            errors.append(exc)

    threads = [threading.Thread(target=worker, args=(s,)) for s in submissions]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    return accepted_count
