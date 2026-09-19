"""
Real, executed tests for bridge-runtime/replay_consumption.py (P1-2).
See HONESTY NOTE in replay_consumption.py: model only, not real
Postgres proof. No network, no DB.
"""
import sys, os
_here = os.path.dirname(os.path.abspath(__file__))
_project_root = os.path.dirname(os.path.dirname(_here))
sys.path.insert(0, os.path.join(_project_root, "bridge-runtime"))

from replay_consumption import (
    ResultSubmission, ResultLedger, DuplicateResultRejected,
    concurrent_duplicate_submission_only_one_wins,
)

results = []


def record(test_id, expected, actual, status, note=""):
    results.append({"TEST": test_id, "EXPECTED": expected, "ACTUAL": actual, "STATUS": status, "NOTE": note})
    print(f"[{status}] {test_id}: expected={expected} actual={actual} {note}")


def run():
    ledger = ResultLedger()
    s1 = ResultSubmission(task_id="T-1", logical_problem_id="LP-1",
                           artifact_digest="deadbeef", correlation_id="C-1")
    accepted = ledger.submit(s1)
    record("P1-2-first-submission-accepted", "T-1", accepted.task_id,
           "PASS" if accepted.task_id == "T-1" else "FAIL")

    # Same logical_problem_id + artifact_digest, DIFFERENT task_id => replay
    s2 = ResultSubmission(task_id="T-2-DIFFERENT", logical_problem_id="LP-1",
                           artifact_digest="deadbeef", correlation_id="C-2-DIFFERENT")
    replay_rejected = False
    try:
        ledger.submit(s2)
    except DuplicateResultRejected:
        replay_rejected = True
    record("P1-2-different-task-id-same-logical-result-is-replay", True, replay_rejected,
           "PASS" if replay_rejected else "FAIL")

    # Different logical_problem_id (genuinely different result) is accepted
    s3 = ResultSubmission(task_id="T-3", logical_problem_id="LP-2",
                           artifact_digest="deadbeef", correlation_id="C-3")
    accepted3 = ledger.submit(s3)
    record("P1-2-different-logical-problem-accepted", "T-3", accepted3.task_id,
           "PASS" if accepted3.task_id == "T-3" else "FAIL")

    # is_consumed reflects committed state
    record("P1-2-is-consumed-true-after-accept", True, ledger.is_consumed("LP-1", "deadbeef"),
           "PASS" if ledger.is_consumed("LP-1", "deadbeef") else "FAIL")
    record("P1-2-is-consumed-false-before-accept", False, ledger.is_consumed("LP-99", "nope"),
           "PASS" if ledger.is_consumed("LP-99", "nope") is False else "FAIL")

    # Concurrent duplicate submission: only one of N racing threads wins
    ledger2 = ResultLedger()
    dupes = [
        ResultSubmission(task_id=f"T-race-{i}", logical_problem_id="LP-RACE",
                          artifact_digest="digest-race", correlation_id=f"C-race-{i}")
        for i in range(12)
    ]
    accepted_count = concurrent_duplicate_submission_only_one_wins(ledger2, dupes)
    record("P1-2-concurrent-duplicate-only-one-wins", 1, accepted_count,
           "PASS" if accepted_count == 1 else "FAIL", note=f"{len(dupes)} concurrent threads raced")

    # Restart-persistence MODEL (see HONESTY NOTE — serialize/reload only)
    blob = ledger.to_json()
    reloaded = ResultLedger.from_json(blob)
    record("P1-2-serialize-reload-model", True, reloaded.is_consumed("LP-1", "deadbeef"),
           "PASS" if reloaded.is_consumed("LP-1", "deadbeef") else "FAIL",
           note="MODEL ONLY — not real Postgres restart durability proof")
    still_replay_protected = False
    try:
        reloaded.submit(ResultSubmission(task_id="T-after-reload", logical_problem_id="LP-1",
                                          artifact_digest="deadbeef", correlation_id="C-after-reload"))
    except DuplicateResultRejected:
        still_replay_protected = True
    record("P1-2-reloaded-ledger-still-replay-protected", True, still_replay_protected,
           "PASS" if still_replay_protected else "FAIL")

    return results


if __name__ == "__main__":
    r = run()
    passed = sum(1 for x in r if x["STATUS"] == "PASS")
    print(f"\n{passed}/{len(r)} replay_consumption algorithm-level tests PASS")
    if passed != len(r):
        sys.exit(1)
