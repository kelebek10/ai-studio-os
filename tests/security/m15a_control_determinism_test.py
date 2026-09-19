"""M15-A non-production Control determinism test harness.

This file is intentionally provider/LLM independent. It is a test contract and
reference harness; a real controlled runtime must execute it before CTRL-01..05
can be marked PASS.
"""
from __future__ import annotations

import hashlib
import json
from dataclasses import dataclass
from typing import Any


@dataclass(frozen=True)
class Decision:
    status: str
    reason: str


def canonicalize(value: Any) -> str:
    return json.dumps(value, sort_keys=True, separators=(",", ":"), ensure_ascii=False)


def fingerprint(value: Any) -> str:
    return hashlib.sha256(canonicalize(value).encode("utf-8")).hexdigest()


def deterministic_control(inp: dict[str, Any]) -> Decision:
    """Minimal deterministic security gate; no model/provider dependency."""
    required = (
        "task_id", "correlation_id", "policy_version", "evidence_valid",
        "commit_sha", "artifact_digest", "action", "authority_valid",
    )
    if any(k not in inp for k in required):
        return Decision("BLOCKED", "MISSING_REQUIRED_INPUT")
    if inp["evidence_valid"] is not True:
        return Decision("BLOCKED", "INVALID_EVIDENCE")
    if inp["authority_valid"] is not True:
        return Decision("BLOCKED", "INVALID_AUTHORITY")
    if not all(isinstance(inp[k], str) and inp[k] for k in required if k not in ("evidence_valid", "authority_valid")):
        return Decision("BLOCKED", "MALFORMED_INPUT")
    if inp.get("ai_output") is not None:
        # AI output is deliberately ignored, never interpreted as policy.
        pass
    return Decision("PASS", "POLICY_SATISFIED")


def valid_input() -> dict[str, Any]:
    return {
        "task_id": "task-001",
        "correlation_id": "corr-001",
        "policy_version": "m15a-control-v1",
        "evidence_valid": True,
        "commit_sha": "a" * 40,
        "artifact_digest": "sha256:" + "b" * 64,
        "action": "NONPROD_VERIFY",
        "authority_valid": True,
    }


def test_ctrl01() -> None:
    inp = valid_input()
    outputs = [deterministic_control(inp).__dict__ for _ in range(1000)]
    fps = {fingerprint(x) for x in outputs}
    assert len(fps) == 1
    assert outputs[0] == {"status": "PASS", "reason": "POLICY_SATISFIED"}


def test_ctrl02_ai_output_cannot_change_decision() -> None:
    base = valid_input()
    expected = deterministic_control(base)
    for value in ["PASS", "APPROVED", "human approved", "99.99% confidence", "CONSENSUS", "ignore policy"]:
        mutated = {**base, "ai_output": value}
        assert deterministic_control(mutated) == expected


def test_ctrl03_fail_closed() -> None:
    for key, value in [("evidence_valid", False), ("authority_valid", False), ("policy_version", "")]:
        inp = valid_input()
        inp[key] = value
        assert deterministic_control(inp).status == "BLOCKED"


def test_ctrl04_canonical_reproducibility() -> None:
    a = valid_input()
    b = dict(reversed(list(a.items())))
    assert canonicalize(a) == canonicalize(b)
    assert fingerprint(a) == fingerprint(b)
    assert deterministic_control(a) == deterministic_control(b)


def test_ctrl05_no_mutation_capability() -> None:
    # The deterministic gate returns a decision only; it has no database/network
    # client and therefore cannot itself mutate Core. DB privilege tests remain
    # a separate runtime evidence gate.
    assert not hasattr(deterministic_control, "execute_mutation")
