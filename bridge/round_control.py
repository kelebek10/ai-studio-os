"""
Conflict round enforcement.

Rule (from AI-CONSORTIUM-WORKING-PROTOCOL.md / task instructions):
- Max 3 conflict rounds per logical_problem_id.
- Round 4 is rejected: BLOCKED / CONFLICT_ROUND_LIMIT_EXCEEDED.
- A new task_id or new conversation must NOT reset the counter for the
  same logical_problem_id — the counter is keyed by logical_problem_id,
  not by task_id or session.
"""
from __future__ import annotations

MAX_ROUNDS = 3


class RoundLimitExceeded(Exception):
    pass


class RoundController:
    def __init__(self) -> None:
        # logical_problem_id -> highest round number seen
        self._rounds: dict[str, int] = {}

    def check_and_register(self, logical_problem_id: str, round_number: int) -> str:
        """
        Returns 'OK' or 'BLOCKED'. Raises nothing; caller decides on state.
        Registration only advances the counter — it never resets, even for
        a new task_id under the same logical_problem_id.
        """
        current = self._rounds.get(logical_problem_id, 0)

        if round_number > MAX_ROUNDS:
            # Do not register round 4+ as a valid advance; just report BLOCKED.
            return "BLOCKED"

        if round_number < current:
            # Stale/duplicate round for an already-advanced problem.
            return "BLOCKED"

        self._rounds[logical_problem_id] = max(current, round_number)
        return "OK"

    def current_round(self, logical_problem_id: str) -> int:
        return self._rounds.get(logical_problem_id, 0)
