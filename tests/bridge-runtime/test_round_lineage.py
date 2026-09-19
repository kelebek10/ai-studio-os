"""
Real, executed tests for bridge-runtime/round_lineage.py (P1-1).
See HONESTY NOTE in round_lineage.py: these prove the in-process
algorithm/model, NOT real Postgres atomicity/durability. No network,
no DB.
"""
import sys, os, threading
_here = os.path.dirname(os.path.abspath(__file__))
_project_root = os.path.dirname(os.path.dirname(_here))
sys.path.insert(0, os.path.join(_project_root, "bridge-runtime"))

from round_lineage import (
    RoundLineageStore, RoundTransitionRejected, MAX_ROUND,
    attempt_round4_is_denied, reset_via_different_dimension_is_rejected,
)

results = []


def record(test_id, expected, actual, status, note=""):
    results.append({"TEST": test_id, "EXPECTED": expected, "ACTUAL": actual, "STATUS": status, "NOTE": note})
    print(f"[{status}] {test_id}: expected={expected} actual={actual} {note}")


def run():
    # Monotonic advance
    store = RoundLineageStore()
    store.advance("LP-1", 1)
    store.advance("LP-1", 2)
    record("P1-1-monotonic-advance", 2, store.current_round("LP-1"),
           "PASS" if store.current_round("LP-1") == 2 else "FAIL")

    # Stale/non-monotonic transition rejected
    rejected = False
    try:
        store.advance("LP-1", 2)  # same as current — not > current
    except RoundTransitionRejected:
        rejected = True
    record("P1-1-stale-transition-rejected", True, rejected, "PASS" if rejected else "FAIL")

    # Round 4 deterministically denied
    store2 = RoundLineageStore()
    denied = attempt_round4_is_denied(store2, "LP-2")
    record("P1-1-round4-denied", True, denied, "PASS" if denied else "FAIL",
           note=f"MAX_ROUND={MAX_ROUND}")

    # Concurrent race: many threads try to advance the same logical_problem_id
    # to rounds 1..3; only monotonic winners succeed, final state is exactly 3,
    # and no round beyond MAX_ROUND is ever recorded.
    store3 = RoundLineageStore()
    logical_problem_id = "LP-3"
    errors = []
    attempts = [1, 2, 3, 1, 2, 3, 4, 4, 2]  # includes stale + over-limit attempts

    def worker(n):
        try:
            store3.advance(logical_problem_id, n)
        except RoundTransitionRejected as exc:
            errors.append(str(exc))

    threads = [threading.Thread(target=worker, args=(n,)) for n in attempts]
    for t in threads:
        t.start()
    for t in threads:
        t.join()
    final_round = store3.current_round(logical_problem_id)
    record("P1-1-concurrent-race-final-round", 3, final_round,
           "PASS" if final_round == 3 else "FAIL",
           note=f"{len(errors)} of {len(attempts)} concurrent attempts correctly rejected")
    record("P1-1-concurrent-race-never-exceeds-max", True, final_round <= MAX_ROUND,
           "PASS" if final_round <= MAX_ROUND else "FAIL")

    # Reset-via-different-dimension rejected (agent/provider/branch/etc. are
    # not part of this store's key space at all — see module docstring)
    store4 = RoundLineageStore()
    not_reset = reset_via_different_dimension_is_rejected(store4, "LP-4")
    record("P1-1-no-reset-via-other-dimension", True, not_reset, "PASS" if not_reset else "FAIL")

    # Restart-persistence MODEL: serialize/reload (see HONESTY NOTE — this is
    # NOT proof against a real Postgres restart)
    store5 = RoundLineageStore()
    store5.advance("LP-5", 1)
    store5.advance("LP-5", 2)
    blob = store5.to_json()
    reloaded = RoundLineageStore.from_json(blob)
    record("P1-1-serialize-reload-model", 2, reloaded.current_round("LP-5"),
           "PASS" if reloaded.current_round("LP-5") == 2 else "FAIL",
           note="MODEL ONLY — not real Postgres restart durability proof")
    # And the reloaded store still enforces the same monotonic/max-round rules
    still_enforced = False
    try:
        reloaded.advance("LP-5", 1)  # stale
    except RoundTransitionRejected:
        still_enforced = True
    record("P1-1-reloaded-store-still-enforces-rules", True, still_enforced,
           "PASS" if still_enforced else "FAIL")

    return results


if __name__ == "__main__":
    r = run()
    passed = sum(1 for x in r if x["STATUS"] == "PASS")
    print(f"\n{passed}/{len(r)} round_lineage algorithm-level tests PASS")
    if passed != len(r):
        sys.exit(1)
