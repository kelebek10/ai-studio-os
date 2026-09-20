"""
COMM-BRIDGE-IMPLEMENT-04 — P1-1: global logical_problem_id round lineage.

HONESTY NOTE — read before citing this as evidence:
This module is a Python MODEL of the atomic SQL pattern specified in
governance/BRIDGE-RUNTIME-V1-PREREQUISITES-v1.0.md section 4:

    UPDATE bridge.round_lineage
    SET highest_round = $2, updated_at = now()
    WHERE logical_problem_id = $1
      AND highest_round < $2
      AND $2 <= 3
    RETURNING highest_round;

The lock-based `RoundLineageStore` below reproduces the same
conditional-update semantics (check-and-set under a single mutex) that
a real Postgres row-level lock / atomic UPDATE would provide. The
threading-based tests demonstrate that, UNDER THIS PYTHON PROCESS'S
OWN LOCK, concurrent callers cannot push highest_round past 3 or apply
a stale/non-monotonic transition.

This does NOT prove:
- Real Postgres transaction isolation / row locking behavior
- Multi-process or multi-host concurrency (only in-process threads)
- Restart durability against a real database (the "restart" test here
  serializes to a JSON file and reloads it in the SAME test process —
  it demonstrates the state shape survives a serialize/deserialize
  cycle, not that a real Postgres instance would recover it after an
  actual process crash)

P1-1 as a runtime criterion against real Postgres remains
BLOCKED / CAPABILITY GAP (no reachable Postgres in this environment,
unchanged since COMM-BRIDGE-IMPLEMENT-02). This module is supporting
algorithm-level evidence for the logic the real migration
(migrations/nonprod/015_bridge_runtime_schema.sql) already encodes as
SQL, not a substitute for testing that SQL against a real database.
"""
from __future__ import annotations
import json
import threading
from dataclasses import dataclass, field


MAX_ROUND = 3


@dataclass
class RoundLineageRow:
    logical_problem_id: str
    highest_round: int = 0


class RoundTransitionRejected(Exception):
    """Raised when a round transition would be non-monotonic or exceed
    MAX_ROUND. Mirrors the real SQL's zero-rows-returned case."""


class RoundLineageStore:
    """Keyed ONLY by logical_problem_id — this is the mechanism that
    prevents an agent/provider/conversation/branch/workflow change from
    resetting the counter: none of those fields are part of the key or
    consulted anywhere in this class. A caller cannot pass a different
    agent_id and get a fresh row; the row is found (or created) purely
    from logical_problem_id."""

    def __init__(self) -> None:
        self._rows: dict[str, RoundLineageRow] = {}
        self._lock = threading.Lock()

    def advance(self, logical_problem_id: str, new_round: int) -> int:
        """Atomic (within this process) conditional advance. Returns the
        new highest_round on success. Raises RoundTransitionRejected on
        any of: new_round > MAX_ROUND, new_round <= current highest_round
        (non-monotonic / stale / replay of an old round number)."""
        with self._lock:
            row = self._rows.get(logical_problem_id)
            current = row.highest_round if row else 0
            if new_round > MAX_ROUND:
                raise RoundTransitionRejected(
                    f"round_limit_exceeded: requested={new_round} max={MAX_ROUND}"
                )
            if new_round <= current:
                raise RoundTransitionRejected(
                    f"stale_or_non_monotonic: requested={new_round} current={current}"
                )
            if row is None:
                row = RoundLineageRow(logical_problem_id=logical_problem_id, highest_round=new_round)
                self._rows[logical_problem_id] = row
            else:
                row.highest_round = new_round
            return row.highest_round

    def current_round(self, logical_problem_id: str) -> int:
        with self._lock:
            row = self._rows.get(logical_problem_id)
            return row.highest_round if row else 0

    # ---- restart-persistence MODEL (serialize/deserialize; see HONESTY NOTE) ----

    def to_json(self) -> str:
        with self._lock:
            return json.dumps({k: v.highest_round for k, v in self._rows.items()})

    @classmethod
    def from_json(cls, blob: str) -> "RoundLineageStore":
        store = cls()
        data = json.loads(blob)
        for logical_problem_id, highest_round in data.items():
            store._rows[logical_problem_id] = RoundLineageRow(logical_problem_id, highest_round)
        return store


def attempt_round4_is_denied(store: RoundLineageStore, logical_problem_id: str) -> bool:
    """Advances a lineage to round 3 (valid), then attempts round 4 and
    confirms it is deterministically denied. Returns True iff round 4
    was correctly rejected and highest_round remained 3."""
    store.advance(logical_problem_id, 1)
    store.advance(logical_problem_id, 2)
    store.advance(logical_problem_id, 3)
    try:
        store.advance(logical_problem_id, 4)
        return False  # should never reach here
    except RoundTransitionRejected:
        return store.current_round(logical_problem_id) == 3


def reset_via_different_dimension_is_rejected(store: RoundLineageStore,
                                               logical_problem_id: str) -> bool:
    """Proves that changing agent/provider/conversation/branch/workflow
    (none of which this store's API even accepts as a key) cannot create
    a second lineage for the same logical_problem_id. Since the store's
    only key is logical_problem_id, any caller — regardless of what
    other dimensions it claims to be operating under — advancing the
    same logical_problem_id continues from the SAME row."""
    store.advance(logical_problem_id, 1)
    store.advance(logical_problem_id, 2)
    # A second "caller" with a totally different context still only has
    # logical_problem_id to key on — there is no other-dimension entry
    # point in this API at all, so the only thing to test is that the
    # row it sees is the same one (current_round == 2, not reset to 0).
    return store.current_round(logical_problem_id) == 2
