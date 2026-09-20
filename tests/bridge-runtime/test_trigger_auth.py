"""
Real, executed tests for the algorithm-level logic in trigger_auth.py.

Scope note (repeated deliberately): these tests prove the functions
behave correctly in isolation. They are NOT TGA-01..08/CAW-07/08
criterion-level evidence — see governance/TGA-CAW-ACCEPTANCE-CRITERIA-v1.0.md
section 4. No network, no DB, no GitHub calls happen here.
"""
import sys, os, time, json
_here = os.path.dirname(os.path.abspath(__file__))          # .../tests/bridge-runtime
_project_root = os.path.dirname(os.path.dirname(_here))      # .../bridge-poc
sys.path.insert(0, os.path.join(_project_root, "bridge-runtime"))

from trigger_auth import (
    sign_envelope, verify_signature, branch_authorized, versions_authorized,
    TriggerReplayGuard, validate_envelope_shape, AppendOnlyAudit, AuditEntry,
    evaluate_trigger, ack_matches_task, check_ack_timeout,
)

SECRET = b"test-secret-not-real"
BRANCH = "phase-1-3-foundation"

results = []


def record(test_id, expected, actual, status, note=""):
    results.append({"TEST": test_id, "EXPECTED": expected, "ACTUAL": actual, "STATUS": status, "NOTE": note})
    print(f"[{status}] {test_id}: expected={expected} actual={actual} {note}")


def base_envelope(**overrides):
    e = {
        "task_id": "T-1", "correlation_id": "C-1", "logical_problem_id": "LP-1",
        "assigned_agent": "AGENT-GPT-001", "branch": BRANCH,
        "policy_version": "v1.0", "permission_version": "v1.0", "round_number": 1,
    }
    e.update(overrides)
    return e


def run():
    # TGA-01/02 algorithm: valid signature accepted, tampered payload rejected
    payload = json.dumps(base_envelope()).encode()
    sig = sign_envelope(payload, SECRET)
    ok = verify_signature(payload, sig, SECRET)
    record("TGA-01-algo", True, ok, "PASS" if ok else "FAIL")

    tampered = payload + b"x"
    ok2 = verify_signature(tampered, sig, SECRET)
    record("TGA-02-algo", False, ok2, "PASS" if ok2 is False else "FAIL")

    # TGA-05 algorithm: wrong secret rejected
    ok3 = verify_signature(payload, sig, b"wrong-secret")
    record("TGA-05-algo", False, ok3, "PASS" if ok3 is False else "FAIL")

    # TGA-03 algorithm: branch match
    record("TGA-03-algo-match", True, branch_authorized(BRANCH, BRANCH), "PASS" if branch_authorized(BRANCH, BRANCH) else "FAIL")
    record("TGA-03-algo-mismatch", False, branch_authorized("main", BRANCH), "PASS" if not branch_authorized("main", BRANCH) else "FAIL")

    # TGA-04 algorithm: version allow-list
    allowed_p, allowed_perm = {"v1.0"}, {"v1.0"}
    record("TGA-04-algo-valid", True, versions_authorized("v1.0", "v1.0", allowed_p, allowed_perm),
           "PASS" if versions_authorized("v1.0", "v1.0", allowed_p, allowed_perm) else "FAIL")
    record("TGA-04-algo-stale", False, versions_authorized("v0.9", "v1.0", allowed_p, allowed_perm),
           "PASS" if not versions_authorized("v0.9", "v1.0", allowed_p, allowed_perm) else "FAIL")

    # TGA-06 algorithm: trigger replay dedup
    guard = TriggerReplayGuard()
    k = guard.trigger_key("AGENT-GPT-001", "T-1", "C-1", "hash1")
    first = guard.is_replay(k)
    second = guard.is_replay(k)
    record("TGA-06-algo", (False, True), (first, second), "PASS" if (first, second) == (False, True) else "FAIL")

    # TGA-07 algorithm: fail-closed schema validation
    bad = base_envelope()
    del bad["branch"]
    missing = validate_envelope_shape(bad)
    record("TGA-07-algo-missing-field", True, "branch" in missing, "PASS" if "branch" in missing else "FAIL")
    ok_env = validate_envelope_shape(base_envelope())
    record("TGA-07-algo-valid-passes", [], ok_env, "PASS" if ok_env == [] else "FAIL")

    # TGA-08 algorithm: append-only audit shape (no delete/mutate API exists)
    audit = AppendOnlyAudit()
    audit.append(AuditEntry(task_id="T-1", event_type="TRIGGER", producer_identity_claim="AGENT-GPT-001",
                             envelope_hash="h", decision="ACCEPT", reason=None))
    has_no_delete = not hasattr(audit, "delete") and not hasattr(audit, "clear") and not hasattr(audit, "remove")
    record("TGA-08-algo-shape", True, has_no_delete and len(audit) == 1,
           "PASS" if has_no_delete and len(audit) == 1 else "FAIL",
           note="shape-only; real DB-enforced immutability is BLOCKED (needs Postgres)")

    # Full evaluate_trigger() composition — accept path
    guard2 = TriggerReplayGuard()
    audit2 = AppendOnlyAudit()
    env = base_envelope()
    payload2 = json.dumps(env).encode()
    sig2 = sign_envelope(payload2, SECRET)
    decision = evaluate_trigger(env, payload2, sig2, SECRET, BRANCH, allowed_p, allowed_perm, guard2, audit2)
    record("TGA-composed-accept", True, decision.accepted, "PASS" if decision.accepted else "FAIL")

    # Full evaluate_trigger() — unauthorized (bad signature) path, TGA-05
    decision2 = evaluate_trigger(env, payload2, "deadbeef", SECRET, BRANCH, allowed_p, allowed_perm, guard2, audit2)
    record("TGA-composed-reject-badsig", False, decision2.accepted,
           "PASS" if not decision2.accepted and decision2.reason.startswith("unauthorized_trigger") else "FAIL")

    # Full evaluate_trigger() — replay of the SAME accepted trigger, TGA-06
    decision3 = evaluate_trigger(env, payload2, sig2, SECRET, BRANCH, allowed_p, allowed_perm, guard2, audit2)
    record("TGA-composed-reject-replay", False, decision3.accepted,
           "PASS" if not decision3.accepted and decision3.reason == "replay" else "FAIL")

    # audit trail actually recorded all three decisions
    record("TGA-audit-trail-length", 3, len(audit2), "PASS" if len(audit2) == 3 else "FAIL")

    # CAW-07 algorithm: correlation matching
    task = base_envelope()
    good_ack = {"task_id": "T-1", "correlation_id": "C-1", "logical_problem_id": "LP-1"}
    bad_ack = {"task_id": "T-1", "correlation_id": "C-WRONG", "logical_problem_id": "LP-1"}
    record("CAW-07-algo-match", True, ack_matches_task(task, good_ack), "PASS" if ack_matches_task(task, good_ack) else "FAIL")
    record("CAW-07-algo-mismatch", False, ack_matches_task(task, bad_ack), "PASS" if not ack_matches_task(task, bad_ack) else "FAIL")

    # CAW-08 algorithm: timeout state transitions
    t0 = 1000.0
    record("CAW-08-algo-waiting", "WAITING", check_ack_timeout(t0, t0 + 5, 30, False),
           "PASS" if check_ack_timeout(t0, t0 + 5, 30, False) == "WAITING" else "FAIL")
    record("CAW-08-algo-timeout", "TIMEOUT", check_ack_timeout(t0, t0 + 31, 30, False),
           "PASS" if check_ack_timeout(t0, t0 + 31, 30, False) == "TIMEOUT" else "FAIL")
    record("CAW-08-algo-acked", "ACKNOWLEDGED", check_ack_timeout(t0, t0 + 31, 30, True),
           "PASS" if check_ack_timeout(t0, t0 + 31, 30, True) == "ACKNOWLEDGED" else "FAIL")

    return results


if __name__ == "__main__":
    r = run()
    passed = sum(1 for x in r if x["STATUS"] == "PASS")
    print(f"\n{passed}/{len(r)} algorithm-level tests PASS")
    print("\nREMINDER: these are algorithm-level results only. Every TGA-01..08 and")
    print("CAW-01..10 CRITERION remains BLOCKED / CAPABILITY GAP per")
    print("governance/TGA-CAW-ACCEPTANCE-CRITERIA-v1.0.md — no real endpoint,")
    print("Bridge, Postgres, or Claude-dispatch mechanism exists in this environment.")
    if passed != len(r):
        sys.exit(1)
