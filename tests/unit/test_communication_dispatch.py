from runtime.communication.core import TaskEnvelope
from runtime.communication.dispatch import ControlledDispatcher

def task(agent="echo"):
    return TaskEnvelope.new(
        agent=agent, task_type="PING", scope="trigger-core",
        source_commit="test", required_evidence=["execution"], prohibited_actions=["free_chat"]
    )

def test_dispatch_ack_result_and_evidence():
    calls=[]
    d=ControlledDispatcher()
    d.register("echo", lambda t: calls.append(t.task_id) or {"ok": True})
    ack,result=d.dispatch(task())
    assert ack.status=="ACK"
    assert result.status=="COMPLETED"
    assert result.result["ok"] is True
    assert result.evidence
    assert len(calls)==1

def test_replay_is_idempotent():
    calls=[]
    d=ControlledDispatcher()
    t=task()
    d.register("echo", lambda t: calls.append(1) or {"ok": True})
    _,r1=d.dispatch(t)
    _,r2=d.dispatch(t)
    assert r1==r2
    assert len(calls)==1

def test_unknown_target_fails_closed():
    d=ControlledDispatcher()
    try:
        d.dispatch(task("missing"))
        assert False
    except PermissionError as e:
        assert str(e)=="UNAUTHORIZED_OR_UNAVAILABLE_TARGET"
