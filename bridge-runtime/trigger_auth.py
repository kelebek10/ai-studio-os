"""
COMM-BRIDGE-IMPLEMENT-03 — algorithm-level logic for TGA-01..08 / CAW-07,08.

HONESTY NOTE:
Every function here is real, pure Python, and really unit-tested in
tests/bridge-runtime/test_trigger_auth.py — but it is NOT a deployed
webhook endpoint, NOT wired to a real GitHub App, and NOT connected to
any live Bridge Runtime or Postgres instance. Passing these unit tests
is evidence for the *algorithms* the future Bridge Runtime would use,
never evidence for TGA-01..08 or CAW-01..10 as criteria — see
governance/TGA-CAW-ACCEPTANCE-CRITERIA-v1.0.md section 4 for the exact
distinction. No network calls happen in this module.
"""
from __future__ import annotations
import hashlib
import hmac
import time
from dataclasses import dataclass, field
from typing import Optional


# ---- TGA-01/02/05: signature verification ----

def sign_envelope(payload_bytes: bytes, secret: bytes) -> str:
    return hmac.new(secret, payload_bytes, hashlib.sha256).hexdigest()


def verify_signature(payload_bytes: bytes, signature: str, secret: bytes) -> bool:
    """Constant-time comparison — avoids timing side-channel leaks."""
    expected = sign_envelope(payload_bytes, secret)
    return hmac.compare_digest(expected, signature)


# ---- TGA-03: repo/branch match ----

def branch_authorized(envelope_branch: str, controlled_branch: str) -> bool:
    return envelope_branch == controlled_branch


# ---- TGA-04: policy/permission version allow-list ----

def versions_authorized(policy_version: str, permission_version: str,
                         allowed_policy: set[str], allowed_permission: set[str]) -> bool:
    return policy_version in allowed_policy and permission_version in allowed_permission


# ---- TGA-06: trigger-layer replay dedup ----

class TriggerReplayGuard:
    """Distinct from the RESULT-level ReplayGuard in the earlier Bridge PoC —
    this one guards the *trigger event itself*, before any task processing."""

    def __init__(self) -> None:
        self._seen: set[str] = set()

    def trigger_key(self, producer_id: str, task_id: str, correlation_id: str,
                     envelope_hash: str) -> str:
        return hashlib.sha256(
            f"{producer_id}:{task_id}:{correlation_id}:{envelope_hash}".encode()
        ).hexdigest()

    def is_replay(self, key: str) -> bool:
        if key in self._seen:
            return True
        self._seen.add(key)
        return False


# ---- TGA-07: fail-closed envelope schema validation ----

REQUIRED_ENVELOPE_FIELDS = [
    "task_id", "correlation_id", "logical_problem_id", "assigned_agent",
    "branch", "policy_version", "permission_version", "round_number",
]


def validate_envelope_shape(envelope: dict) -> list[str]:
    """Returns list of missing/invalid fields; empty = structurally valid.
    Structural validity is necessary but NOT sufficient for dispatch —
    TGA-01/03/04/05/06 must all also pass."""
    missing = []
    for f in REQUIRED_ENVELOPE_FIELDS:
        if f not in envelope or envelope[f] in (None, ""):
            missing.append(f)
    if "round_number" in envelope and not isinstance(envelope.get("round_number"), int):
        missing.append("round_number:not_int")
    return missing


# ---- TGA-08: append-only audit log (shape-level; not DB-enforced) ----

@dataclass
class AuditEntry:
    task_id: Optional[str]
    event_type: str
    producer_identity_claim: Optional[str]
    envelope_hash: Optional[str]
    decision: str
    reason: Optional[str]
    ts: float = field(default_factory=time.time)


class AppendOnlyAudit:
    """In-memory stand-in proving the *shape* of append-only behavior.
    NOT equivalent to the real Postgres governance.reject_mutation()
    trigger — that guarantee requires the actual database (TGA-08 real
    criterion remains BLOCKED, see contract doc)."""

    def __init__(self) -> None:
        self._log: list[AuditEntry] = []

    def append(self, entry: AuditEntry) -> None:
        self._log.append(entry)

    def entries(self) -> tuple[AuditEntry, ...]:
        return tuple(self._log)  # read-only view; no delete/mutate method exists

    def __len__(self) -> int:
        return len(self._log)


# ---- Full TGA gate, composing the above (still logic-only) ----

@dataclass
class TriggerDecision:
    accepted: bool
    reason: Optional[str] = None


def evaluate_trigger(envelope: dict, raw_payload: bytes, signature: str,
                      secret: bytes, controlled_branch: str,
                      allowed_policy: set[str], allowed_permission: set[str],
                      replay_guard: TriggerReplayGuard,
                      audit: AppendOnlyAudit) -> TriggerDecision:
    envelope_hash = hashlib.sha256(raw_payload).hexdigest()
    producer_claim = envelope.get("assigned_agent")  # placeholder claim field

    def deny(reason: str) -> TriggerDecision:
        audit.append(AuditEntry(
            task_id=envelope.get("task_id"), event_type="TRIGGER",
            producer_identity_claim=producer_claim, envelope_hash=envelope_hash,
            decision="DENY", reason=reason,
        ))
        return TriggerDecision(False, reason)

    shape_errors = validate_envelope_shape(envelope)
    if shape_errors:
        return deny(f"malformed_envelope:{shape_errors}")

    if not verify_signature(raw_payload, signature, secret):
        return deny("unauthorized_trigger:bad_signature")

    if not branch_authorized(envelope["branch"], controlled_branch):
        return deny("wrong_branch")

    if not versions_authorized(envelope["policy_version"], envelope["permission_version"],
                                allowed_policy, allowed_permission):
        return deny("invalid_policy_or_permission")

    key = replay_guard.trigger_key(
        producer_claim, envelope["task_id"], envelope["correlation_id"], envelope_hash
    )
    if replay_guard.is_replay(key):
        return deny("replay")

    audit.append(AuditEntry(
        task_id=envelope.get("task_id"), event_type="TRIGGER",
        producer_identity_claim=producer_claim, envelope_hash=envelope_hash,
        decision="ACCEPT", reason=None,
    ))
    return TriggerDecision(True, None)


# ---- CAW-07: correlation/logical_problem_id match ----

def ack_matches_task(task: dict, ack: dict) -> bool:
    return (
        task.get("task_id") == ack.get("task_id")
        and task.get("correlation_id") == ack.get("correlation_id")
        and task.get("logical_problem_id") == ack.get("logical_problem_id")
    )


# ---- CAW-08: timeout state transition ----

def check_ack_timeout(dispatched_at: float, now: float, timeout_seconds: int,
                       ack_received: bool) -> str:
    if ack_received:
        return "ACKNOWLEDGED"
    if (now - dispatched_at) >= timeout_seconds:
        return "TIMEOUT"
    return "WAITING"
