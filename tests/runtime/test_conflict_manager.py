from tempfile import TemporaryDirectory
from uuid import uuid4
from runtime.communication.core import TaskEnvelope, TaskState
from runtime.conflict_manager import ConflictManager

SOURCE = "12cff6ba26a2386e1866504601177305641d7383"

def task(problem):
    return TaskEnvelope.new(agent="reviewer", task_type="conflict", scope="M16.9",
                            source_commit=SOURCE, required_evidence=["conflict-record"],
                            prohibited_actions=["reset-conflict"], logical_problem_id=problem)

def main():
    with TemporaryDirectory() as d:
        path = f"{d}/conflicts.db"
        problem = uuid4()
        manager = ConflictManager(path)
        t = task(problem)
        for expected in (1, 2, 3):
            t, rec = manager.open_round(t, model=f"model-{expected}")
            assert t.conflict_round == expected and rec.round_number == expected and rec.status == "OPEN"
        blocked, rec = manager.open_round(t, model="model-4")
        assert blocked.status is TaskState.BLOCKED and blocked.conflict_round == 4
        assert rec.reason == "CONFLICT_ROUND_LIMIT_EXCEEDED"
        manager.close()

        restarted = ConflictManager(path)
        try:
            restarted.open_round(task(problem), model="new-model")
            raise AssertionError("same logical problem was reset")
        except ValueError as exc:
            assert str(exc) == "CONFLICT_LOGICAL_PROBLEM_CLOSED"
        assert len(restarted.records()) == 4
        restarted.close()

        missing = ConflictManager(":memory:")
        try:
            missing.open_round(task(None), model="model")
            raise AssertionError("missing logical problem was accepted")
        except ValueError as exc:
            assert str(exc) == "CONFLICT_REQUIRES_LOGICAL_PROBLEM_ID"
        missing.close()

        scoped = ConflictManager(":memory:")
        blocked2, rec2 = scoped.open_round(task(uuid4()), model="model", scope_match=False)
        assert blocked2.status is TaskState.BLOCKED and rec2.reason == "CONFLICT_CONTROL_BLOCKED"
        scoped.close()

    print("M16.9 CONFLICT MANAGER HARNESS: PASS")

if __name__ == "__main__":
    main()
