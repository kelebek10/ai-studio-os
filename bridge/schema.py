"""
PAI-FORGE Communication Bridge PoC — Schema definitions.

This module defines the minimum required fields for TASK and RESULT
messages exchanged between GPT (control plane) and Claude (worker),
using GitHub Issue/Comment records as the communication plane.

No network calls. No secrets. Pure data validation logic.
"""
from __future__ import annotations
from dataclasses import dataclass, field
from typing import Any


TASK_REQUIRED_FIELDS = [
    "task_id",
    "correlation_id",
    "logical_problem_id",
    "parent_task_id",
    "assigned_agent",
    "task_type",
    "scope",
    "branch",
    "source_commit",
    "policy_version",
    "permission_version",
    "required_evidence",
    "prohibited_actions",
    "timeout",
    "round_number",
]

RESULT_REQUIRED_FIELDS = [
    "task_id",
    "correlation_id",
    "logical_problem_id",
    "agent_id",
    "producer_status",
    "source_commit",
    "artifact_digest",
    "changed_files",
    "tests",
    "evidence_refs",
    "risks",
    "gaps",
    "recommended_next_action",
    "human_action_required",
]

VALID_STATES = [
    "TASK_CREATED",
    "TASK_DISPATCHED",
    "ACKNOWLEDGED",
    "WORKING",
    "RESULT_SUBMITTED",
    "GPT_REVIEW",
    "VERIFIED",
    "REWORK_REQUIRED",
    "HUMAN_ACTION_REQUIRED",
    "BLOCKED",
    "TIMEOUT",
    "CLOSED",
]


class SchemaValidationError(Exception):
    pass


# Fields that are required to be *present* but may legitimately hold None
# (e.g. a root task has no parent).
NULLABLE_FIELDS = {"parent_task_id"}


def _missing_fields(payload: dict, required: list[str]) -> list[str]:
    missing = []
    for f in required:
        if f not in payload:
            missing.append(f)
            continue
        if f in NULLABLE_FIELDS:
            continue  # presence is enough; None is a valid value
        if payload[f] in (None, ""):
            missing.append(f)
    return missing


def validate_task(payload: dict) -> list[str]:
    """Return list of missing/invalid fields; empty list = valid."""
    return _missing_fields(payload, TASK_REQUIRED_FIELDS)


def validate_result(payload: dict) -> list[str]:
    return _missing_fields(payload, RESULT_REQUIRED_FIELDS)


@dataclass
class BridgeRecord:
    """A single communication-plane record (maps 1:1 to a GitHub comment)."""
    state: str
    payload: dict
    raw_ref: str = ""  # e.g. issue/comment URL when actually posted to GitHub
