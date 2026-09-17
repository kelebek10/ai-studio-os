"""
PAI-FORGE Communication Bridge PoC — orchestrator.

IMPORTANT / HONESTY NOTE:
This module implements and tests the CONTROL LOGIC of the bridge
(schema validation, round limiting, replay protection, fail-closed
gating, deterministic verification) entirely locally/synchronously.

It does NOT implement, and does not claim to implement, an
always-on listener that automatically wakes a Claude session when
GPT posts a GitHub comment. See README-BRIDGE-POC.md /
COMMUNICATION_BRIDGE_STATUS for what is PASS vs UNVERIFIED.

Where a "GPT" or "Claude worker" actor is needed for a test, a MOCK
callable is injected by the caller (see tests). No live GPT process,
no live Claude auto-wake, no network calls, no secrets are used here.
"""
from __future__ import annotations
from dataclasses import dataclass, field
from typing import Callable, Optional

from .schema import validate_task, validate_result, VALID_STATES
from .round_control import RoundController, MAX_ROUNDS
from .replay_protection import ReplayGuard


FAIL_CLOSED_REASONS = {
    "MISSING_TASK": "missing task",
    "WRONG_AGENT": "wrong agent",
    "WRONG_CORRELATION": "wrong correlation",
    "WRONG_LOGICAL_PROBLEM": "wrong logical problem",
    "WRONG_BRANCH": "wrong branch",
    "WRONG_SOURCE_COMMIT": "wrong source commit",
    "MISSING_EVIDENCE": "missing evidence",
    "INVALID_PERMISSION": "invalid permission",
    "INVALID_POLICY": "invalid policy",
    "DUPLICATE": "duplicate",
    "REPLAY": "replay",
    "TIMEOUT": "timeout",
    "ROUND_LIMIT": "round > 3",
    "HUMAN_APPROVAL_REQUIRED": "human approval required",
}


@dataclass
class BridgeResult:
    state: str
    reason: Optional[str] = None
    detail: Optional[dict] = None


class CommunicationBridge:
    """
    Deterministic control-plane logic. Given identical inputs, produces
    identical outputs (see TEST-15 determinism check).
    """

    def __init__(self, expected_branch: str, expected_agent: str,
                 allowed_policy_versions: set[str], allowed_permission_versions: set[str]):
        self.expected_branch = expected_branch
        self.expected_agent = expected_agent
        self.allowed_policy_versions = allowed_policy_versions
        self.allowed_permission_versions = allowed_permission_versions
        self.round_controller = RoundController()
        self.replay_guard = ReplayGuard()
        self._known_source_commits: set[str] = set()
        self._known_correlations: dict[str, str] = {}  # correlation_id -> logical_problem_id

    def register_valid_commit(self, sha: str) -> None:
        self._known_source_commits.add(sha)

    # ---- TASK_CREATED / TASK_DISPATCHED ----

    def create_task(self, task: dict) -> BridgeResult:
        missing = validate_task(task)
        if missing:
            return BridgeResult("BLOCKED", "missing task", {"missing_fields": missing})
        return BridgeResult("TASK_CREATED", detail={"task_id": task["task_id"]})

    def dispatch_task(self, task: dict) -> BridgeResult:
        created = self.create_task(task)
        if created.state != "TASK_CREATED":
            return created

        if task["assigned_agent"] != self.expected_agent:
            return BridgeResult("BLOCKED", "wrong agent", {"got": task["assigned_agent"]})

        if task["branch"] != self.expected_branch:
            return BridgeResult("BLOCKED", "wrong branch", {"got": task["branch"]})

        if task["source_commit"] not in self._known_source_commits:
            return BridgeResult("BLOCKED", "wrong source commit", {"got": task["source_commit"]})

        if task["policy_version"] not in self.allowed_policy_versions:
            return BridgeResult("BLOCKED", "invalid policy", {"got": task["policy_version"]})

        if task["permission_version"] not in self.allowed_permission_versions:
            return BridgeResult("BLOCKED", "invalid permission", {"got": task["permission_version"]})

        round_status = self.round_controller.check_and_register(
            task["logical_problem_id"], task["round_number"]
        )
        if round_status == "BLOCKED":
            return BridgeResult("BLOCKED", "round > 3", {
                "logical_problem_id": task["logical_problem_id"],
                "round_number": task["round_number"],
            })

        self._known_correlations[task["correlation_id"]] = task["logical_problem_id"]
        return BridgeResult("TASK_DISPATCHED", detail={"task_id": task["task_id"]})

    # ---- ACK / WORKING (worker side; caller supplies the worker callable) ----

    def acknowledge(self, task: dict, worker_ack: Callable[[dict], bool]) -> BridgeResult:
        dispatched = self.dispatch_task(task)
        if dispatched.state != "TASK_DISPATCHED":
            return dispatched
        ok = worker_ack(task)
        if not ok:
            return BridgeResult("TIMEOUT", "timeout", {"task_id": task["task_id"]})
        return BridgeResult("ACKNOWLEDGED", detail={"task_id": task["task_id"]})

    # ---- RESULT_SUBMITTED / GPT_REVIEW / VERIFIED ----

    def submit_result(self, task: dict, result: dict) -> BridgeResult:
        missing = validate_result(result)
        if missing:
            return BridgeResult("BLOCKED", "missing evidence", {"missing_fields": missing})

        if result["task_id"] != task["task_id"]:
            return BridgeResult("BLOCKED", "missing task", {"reason": "task_id mismatch"})

        if result["correlation_id"] != task["correlation_id"]:
            return BridgeResult("BLOCKED", "wrong correlation", {
                "expected": task["correlation_id"], "got": result["correlation_id"]
            })

        if result["logical_problem_id"] != task["logical_problem_id"]:
            return BridgeResult("BLOCKED", "wrong logical problem", {
                "expected": task["logical_problem_id"], "got": result["logical_problem_id"]
            })

        if self.replay_guard.is_replay(
            result["task_id"], result["correlation_id"], result["artifact_digest"]
        ):
            return BridgeResult("BLOCKED", "replay", {"task_id": result["task_id"]})

        if not result["evidence_refs"]:
            return BridgeResult("BLOCKED", "missing evidence", {"task_id": result["task_id"]})

        return BridgeResult("RESULT_SUBMITTED", detail={"task_id": result["task_id"]})

    def gpt_review(self, submitted: BridgeResult, result: dict) -> BridgeResult:
        if submitted.state != "RESULT_SUBMITTED":
            return submitted

        if result.get("human_action_required") is True:
            return BridgeResult("HUMAN_ACTION_REQUIRED", detail={
                "task_id": result["task_id"],
                "reason": result.get("recommended_next_action"),
            })

        if result.get("producer_status") == "TIMEOUT":
            return BridgeResult("TIMEOUT", "timeout", {"task_id": result["task_id"]})

        # Deterministic verification: PASS only if producer_status is
        # explicitly PASS *and* every declared test result is PASS.
        tests = result.get("tests") or []
        all_tests_pass = bool(tests) and all(t.get("result") == "PASS" for t in tests)

        if result.get("producer_status") == "PASS" and all_tests_pass:
            return BridgeResult("VERIFIED", detail={"task_id": result["task_id"]})

        return BridgeResult("REWORK_REQUIRED", detail={"task_id": result["task_id"]})
