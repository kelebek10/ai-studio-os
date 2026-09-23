from __future__ import annotations
from dataclasses import dataclass
import sqlite3
from pathlib import Path
from uuid import UUID
from .communication.core import MAX_CONFLICT_ROUNDS, ControlDecision, TaskEnvelope, TaskState

@dataclass(frozen=True)
class ConflictRecord:
    logical_problem_id: UUID
    round_number: int
    task_id: UUID
    agent: str
    model: str
    status: str
    reason: str

class ConflictManager:
    """Deterministic conflict manager with durable non-production lineage storage."""

    def __init__(self, storage_path: str | Path = ":memory:") -> None:
        self._db = sqlite3.connect(str(storage_path))
        self._db.execute(
            "CREATE TABLE IF NOT EXISTS conflict_records "
            "(logical_problem_id TEXT NOT NULL, round_number INTEGER NOT NULL, "
            "task_id TEXT NOT NULL, agent TEXT NOT NULL, model TEXT NOT NULL, "
            "status TEXT NOT NULL, reason TEXT NOT NULL, "
            "PRIMARY KEY(logical_problem_id, round_number))"
        )
        self._db.commit()

    def open_round(self, task: TaskEnvelope, *, model: str,
                   scope_match: bool = True, actionable: bool = True) -> tuple[TaskEnvelope, ConflictRecord]:
        if task.logical_problem_id is None:
            raise ValueError("CONFLICT_REQUIRES_LOGICAL_PROBLEM_ID")
        if task.status in {TaskState.BLOCKED, TaskState.COMPLETED, TaskState.HUMAN_GATE}:
            raise ValueError("CONFLICT_REQUIRES_OPEN_TASK")
        problem = str(task.logical_problem_id)
        row = self._db.execute(
            "SELECT MAX(round_number) FROM conflict_records WHERE logical_problem_id=?", (problem,)
        ).fetchone()
        current = int(row[0] or 0)
        if self._db.execute(
            "SELECT 1 FROM conflict_records WHERE logical_problem_id=? AND status='BLOCKED' LIMIT 1", (problem,)
        ).fetchone():
            raise ValueError("CONFLICT_LOGICAL_PROBLEM_CLOSED")
        next_round = current + 1
        decision = self._authorize(next_round, scope_match, actionable)
        status = "OPEN" if decision is ControlDecision.ALLOW else "BLOCKED"
        reason = ("CONFLICT_ROUND_ALLOWED" if status == "OPEN" else
                  ("CONFLICT_ROUND_LIMIT_EXCEEDED" if next_round > MAX_CONFLICT_ROUNDS
                   else "CONFLICT_CONTROL_BLOCKED"))
        record = ConflictRecord(task.logical_problem_id, next_round, task.task_id,
                                task.agent, model, status, reason)
        self._db.execute(
            "INSERT INTO conflict_records VALUES (?,?,?,?,?,?,?)",
            (problem, next_round, str(task.task_id), task.agent, model, status, reason),
        )
        self._db.commit()
        data = {**task.__dict__, "conflict_round": next_round}
        if status == "BLOCKED":
            data["status"] = TaskState.BLOCKED
        return task.__class__(**data), record

    @staticmethod
    def _authorize(round_number: int, scope_match: bool, actionable: bool) -> ControlDecision:
        if not scope_match or not actionable or round_number < 1 or round_number > MAX_CONFLICT_ROUNDS:
            return ControlDecision.BLOCKED
        return ControlDecision.ALLOW

    def records(self) -> tuple[ConflictRecord, ...]:
        rows = self._db.execute(
            "SELECT logical_problem_id, round_number, task_id, agent, model, status, reason "
            "FROM conflict_records ORDER BY rowid"
        ).fetchall()
        return tuple(ConflictRecord(UUID(r[0]), r[1], UUID(r[2]), r[3], r[4], r[5], r[6]) for r in rows)

    def close(self) -> None:
        self._db.close()
