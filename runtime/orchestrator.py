from __future__ import annotations

from dataclasses import dataclass

from .agent_registry import AgentRegistry, ORCHESTRATOR
from .communication.core import TaskEnvelope, TaskState
from .provider_contract import Authority, DEFAULT_PROVIDER_CONTRACTS, Provider
from .model_adapter import ModelAdapter, ModelResponse


@dataclass(frozen=True)
class ProviderAssignment:
    provider: Provider
    agent_id: str
    scope: str
    authority: Authority = Authority.EXECUTE


class Orchestrator:
    """Central authority for task assignment; providers remain untrusted executors."""

    def __init__(self, registry: AgentRegistry | None = None) -> None:
        # Registry may be in-memory (tests) or PersistentAgentRegistry (runtime).
        self.registry = registry or AgentRegistry()

    def assign_provider(self, task: TaskEnvelope, provider: Provider, authority: Authority = Authority.EXECUTE) -> ProviderAssignment:
        contract = DEFAULT_PROVIDER_CONTRACTS[provider]
        if not contract.can(authority):
            raise PermissionError(f"PROVIDER_AUTHORITY_DENIED:{authority.value}")
        if task.scope not in contract.allowed_scopes:
            raise PermissionError("PROVIDER_SCOPE_DENIED")
        return ProviderAssignment(provider=provider, agent_id=task.agent, scope=task.scope, authority=authority)


    def execute_provider_task(self, task: TaskEnvelope, provider: Provider, adapter: ModelAdapter, prompt: str) -> ModelResponse:
        assignment = self.assign_provider(task, provider, Authority.EXECUTE)
        agent = self.registry.get(assignment.agent_id)
        if agent is None or agent.status.value != "ACTIVE":
            raise PermissionError("AGENT_NOT_REGISTERED_OR_INACTIVE")
        if agent.provider != provider.value:
            raise PermissionError("AGENT_PROVIDER_MISMATCH")
        executing = task.transition(TaskState.ROUTING).transition(TaskState.EXECUTING)
        return adapter.execute(executing, prompt)

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
