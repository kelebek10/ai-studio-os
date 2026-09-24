from dataclasses import dataclass, field
from enum import Enum


class Provider(str, Enum):
    GEMINI = "GEMINI"
    CLAUDE = "CLAUDE"
    COPILOT = "COPILOT"
    QWEN = "QWEN"


class Authority(str, Enum):
    EXECUTE = "EXECUTE"
    REVIEW = "REVIEW"
    EVIDENCE = "EVIDENCE"
    APPROVE = "APPROVE"
    PROVISION = "PROVISION"


DENIED_AUTHORITIES = frozenset({Authority.APPROVE, Authority.PROVISION})
DEFAULT_AUTHORITIES = frozenset({Authority.EXECUTE, Authority.REVIEW, Authority.EVIDENCE})


@dataclass(frozen=True)
class ProviderContract:
    provider: Provider
    authorities: frozenset[Authority] = field(default_factory=lambda: DEFAULT_AUTHORITIES)
    allowed_scopes: frozenset[str] = field(default_factory=lambda: frozenset({"TASK_SCOPED"}))

    def validate(self) -> None:
        denied = self.authorities & DENIED_AUTHORITIES
        if denied:
            names = ",".join(sorted(a.value for a in denied))
            raise ValueError(f"PROVIDER_AUTHORITY_DENIED:{names}")

    def can(self, authority: Authority) -> bool:
        self.validate()
        return authority in self.authorities and authority not in DENIED_AUTHORITIES


DEFAULT_PROVIDER_CONTRACTS = {
    provider: ProviderContract(provider=provider) for provider in Provider
}


def assert_provider_cannot_provision(provider: Provider) -> None:
    contract = DEFAULT_PROVIDER_CONTRACTS[provider]
    if contract.can(Authority.PROVISION):
        raise AssertionError("AI_PROVIDER_PROVISION_AUTHORITY_MUST_BE_DENIED")


def assert_provider_cannot_approve(provider: Provider) -> None:
    contract = DEFAULT_PROVIDER_CONTRACTS[provider]
    if contract.can(Authority.APPROVE):
        raise AssertionError("AI_PROVIDER_APPROVAL_AUTHORITY_MUST_BE_DENIED")
