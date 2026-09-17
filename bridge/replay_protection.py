"""
Replay / duplicate detection.

A (task_id, correlation_id, artifact_digest) tuple that has already been
accepted as a RESULT must not be processed again as a new event. This
guards against the same GitHub comment (or a copy of it) being replayed
into the bridge twice.
"""
from __future__ import annotations


class ReplayGuard:
    def __init__(self) -> None:
        self._seen: set[tuple[str, str, str]] = set()

    def is_replay(self, task_id: str, correlation_id: str, artifact_digest: str) -> bool:
        key = (task_id, correlation_id, artifact_digest)
        if key in self._seen:
            return True
        self._seen.add(key)
        return False
