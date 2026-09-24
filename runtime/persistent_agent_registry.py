from __future__ import annotations

from dataclasses import dataclass
from typing import Protocol

from .agent_registry import AgentDefinition, AgentRegistry, AgentStatus, AgentTier


class Connection(Protocol):
    def execute(self, query: str, params: tuple = ()): ...


@dataclass(frozen=True)
class RegistryLimits:
    max_core: int = 12
    max_specialists: int = 36
    max_per_provider: int = 9


class PersistentAgentRegistry:
    """Production-boundary adapter; DB principals enforce authority, not caller metadata."""

    def __init__(self, connection, limits: RegistryLimits = RegistryLimits()):
        self.connection = connection
        self.limits = limits

    def list_active(self) -> tuple[AgentDefinition, ...]:
        cur = self.connection.execute(
            "SELECT agent_id,name,tier,scope,provider,parent_agent_id,status,approval_id "
            "FROM m18_agent_registry.agent WHERE status='ACTIVE' ORDER BY agent_id"
        )
        return tuple(AgentDefinition(
            agent_id=r[0], name=r[1], tier=AgentTier(r[2]), scope=r[3],
            provider=r[4], parent_agent_id=r[5], status=AgentStatus(r[6]), approval_id=r[7]
        ) for r in cur.fetchall())


    def get(self, agent_id: str) -> AgentDefinition | None:
        cur = self.connection.execute(
            "SELECT agent_id,name,tier,scope,provider,parent_agent_id,status,approval_id "
            "FROM m18_agent_registry.agent WHERE agent_id=%s", (agent_id,)
        )
        r = cur.fetchone()
        if r is None:
            return None
        return AgentDefinition(
            agent_id=r[0], name=r[1], tier=AgentTier(r[2]), scope=r[3],
            provider=r[4], parent_agent_id=r[5], status=AgentStatus(r[6]), approval_id=r[7]
        )

    def request_core_addition(self, name: str, scope: str) -> str:
        if not name or not scope:
            return 'BLOCKED:INVALID_CORE_AGENT_REQUEST'
        cur = self.connection.execute(
            "SELECT count(*) FROM m18_agent_registry.agent WHERE tier='CORE' AND status='ACTIVE'"
        )
        if cur.fetchone()[0] >= self.limits.max_core:
            return 'BLOCKED:CORE_AGENT_LIMIT_REACHED'
        return f'HUMAN_GATE:CREATE_CORE_AGENT:{name}:{scope}'

    def create_specialist(self, *, name: str, provider: str, scope: str, parent_agent_id: str, created_by: str) -> str:
        if created_by != "ORCHESTRATOR":
            raise PermissionError("SPECIALIST_CREATION_REQUIRES_ORCHESTRATOR")
        return self.provision_specialist(name, provider, scope, parent_agent_id)

    def provision_specialist(self, name: str, provider: str, scope: str, parent_agent_id: str) -> str:
        agent_id = f"specialist:{provider.lower()}:{name.lower().replace(' ', '-')}"
        self.connection.execute(
            "INSERT INTO m18_agent_registry.agent(agent_id,name,tier,scope,provider,parent_agent_id) "
            "VALUES (%s,%s,'SPECIALIST',%s,%s,%s)",
            (agent_id, name, scope, provider.upper(), parent_agent_id),
        )
        return agent_id

    def provision_core(self, name: str, scope: str, approval_id: str) -> str:
        agent_id = f"core:{name.lower().replace(' ', '-')}"
        self.connection.execute(
            "INSERT INTO m18_agent_registry.agent(agent_id,name,tier,scope,approval_id) "
            "VALUES (%s,%s,'CORE',%s,%s)",
            (agent_id, name, scope, approval_id),
        )
        return agent_id
