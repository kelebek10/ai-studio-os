from __future__ import annotations

from dataclasses import dataclass
from enum import Enum


class AgentTier(str, Enum):
    CORE = "CORE"
    SPECIALIST = "SPECIALIST"


class AgentStatus(str, Enum):
    ACTIVE = "ACTIVE"
    DISABLED = "DISABLED"


ORCHESTRATOR = "ORCHESTRATOR"
HUMAN = "HUMAN"
AI_PROVIDERS = frozenset({"GEMINI", "CLAUDE", "COPILOT", "QWEN"})


@dataclass(frozen=True)
class HumanApproval:
    approval_id: str
    principal: str
    reason: str


@dataclass(frozen=True)
class AgentDefinition:
    agent_id: str
    name: str
    tier: AgentTier
    scope: str
    provider: str | None = None
    parent_agent_id: str | None = None
    status: AgentStatus = AgentStatus.ACTIVE
    approval_id: str | None = None


class AgentRegistry:
    """Bounded registry; providers never receive provisioning authority."""

    def __init__(self, max_core: int = 12, max_specialists: int = 36, max_per_provider: int = 9):
        if min(max_core, max_specialists, max_per_provider) < 1:
            raise ValueError("INVALID_AGENT_LIMITS")
        self._limits = (max_core, max_specialists, max_per_provider)
        self._agents: dict[str, AgentDefinition] = {}

    def _unique(self, agent_id: str) -> None:
        if agent_id in self._agents:
            raise ValueError("AGENT_ID_ALREADY_REGISTERED")

    def create_core(self, name: str, scope: str, approval: HumanApproval) -> AgentDefinition:
        cores = sum(a.tier is AgentTier.CORE for a in self._agents.values())
        if cores >= self._limits[0]:
            raise PermissionError("CORE_AGENT_LIMIT_REACHED")
        if approval.principal != HUMAN:
            raise PermissionError("CORE_AGENT_APPROVAL_MUST_BE_HUMAN")
        agent_id = "core:" + name.lower().replace(" ", "-")
        self._unique(agent_id)
        agent = AgentDefinition(agent_id, name, AgentTier.CORE, scope,
                                approval_id=approval.approval_id)
        self._agents[agent_id] = agent
        return agent

    def create_specialist(self, name: str, provider: str, scope: str,
                          parent_agent_id: str, created_by: str = ORCHESTRATOR) -> AgentDefinition:
        if created_by != ORCHESTRATOR:
            raise PermissionError("ONLY_ORCHESTRATOR_MAY_CREATE_SPECIALIST")
        provider = provider.upper()
        if provider not in AI_PROVIDERS:
            raise PermissionError("UNREGISTERED_AI_PROVIDER")
        parent = self._agents.get(parent_agent_id)
        if parent is None or parent.tier is not AgentTier.CORE:
            raise PermissionError("SPECIALIST_PARENT_MUST_BE_CORE")
        specialists = [a for a in self._agents.values() if a.tier is AgentTier.SPECIALIST]
        if len(specialists) >= self._limits[1]:
            raise PermissionError("SPECIALIST_AGENT_LIMIT_REACHED")
        if sum(a.provider == provider for a in specialists) >= self._limits[2]:
            raise PermissionError("PROVIDER_SPECIALIST_LIMIT_REACHED")
        agent_id = f"specialist:{provider.lower()}:{name.lower().replace(' ', '-') }"
        self._unique(agent_id)
        agent = AgentDefinition(agent_id, name, AgentTier.SPECIALIST, scope,
                                provider=provider, parent_agent_id=parent_agent_id)
        self._agents[agent_id] = agent
        return agent

    def request_core_addition(self, name: str, scope: str) -> str:
        cores = sum(a.tier is AgentTier.CORE for a in self._agents.values())
        if cores >= self._limits[0]:
            return "BLOCKED:CORE_AGENT_LIMIT_REACHED"
        if not name or not scope:
            return "BLOCKED:INVALID_CORE_AGENT_REQUEST"
        return f"HUMAN_GATE:CREATE_CORE_AGENT:{name}:{scope}"

    def get(self, agent_id: str) -> AgentDefinition | None:
        return self._agents.get(agent_id)

    def all(self) -> tuple[AgentDefinition, ...]:
        return tuple(self._agents.values())


def assert_provider_cannot_provision(caller: str) -> None:
    if caller.upper() in AI_PROVIDERS:
        raise PermissionError("AI_PROVIDER_HAS_NO_AGENT_PROVISIONING_AUTHORITY")
