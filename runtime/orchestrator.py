from __future__ import annotations

from dataclasses import dataclass

from .agent_registry import AgentRegistry, ORCHESTRATOR
from .communication.core import TaskEnvelope
from .provider_contract import Authority, DEFAULT_PROVIDER_CONTRACTS, Provider


@dataclass(frozen=True)
class ProviderAssignment:
    provider: Provider
    agent_id: str
    scope: str
    authority: Authority = Authority.EXECUTE


class Orchestrator:
    """Central authority for task assignment; providers remain untrusted executors."""

    def __init__(self, registry: AgentRegistry | None = None) -> None:
        self.registry = registry or AgentRegistry()

    def assign_provider(self, task: TaskEnvelope, provider: Provider, authority: Authority = Authority.EXECUTE) -> ProviderAssignment:
        contract = DEFAULT_PROVIDER_CONTRACTS[provider]
        if not contract.can(authority):
            raise PermissionError(f"PROVIDER_AUTHORITY_DENIED:{authority.value}")
        if task.scope not in contract.allowed_scopes:
            raise PermissionError("PROVIDER_SCOPE_DENIED")
        return ProviderAssignment(provider=provider, agent_id=task.agent, scope=task.scope, authority=authority)

    def provision_specialist(self, *, name: str, provider: Provider, scope: str, parent_agent_id: str):
        return self.registry.create_specialist(
            name=name,
            provider=provider.value,
            scope=scope,
            parent_agent_id=parent_agent_id,
            created_by=ORCHESTRATOR,
        )

    def request_core_agent(self, *, name: str, scope: str) -> str:
        return self.registry.request_core_addition(name, scope)
