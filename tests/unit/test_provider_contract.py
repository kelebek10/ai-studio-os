import pytest

from runtime.provider_contract import (
    Authority,
    DEFAULT_PROVIDER_CONTRACTS,
    Provider,
    ProviderContract,
    assert_provider_cannot_approve,
    assert_provider_cannot_provision,
)


@pytest.mark.parametrize("provider", list(Provider))
def test_provider_defaults_are_execution_only(provider):
    contract = DEFAULT_PROVIDER_CONTRACTS[provider]
    assert contract.can(Authority.EXECUTE)
    assert contract.can(Authority.REVIEW)
    assert contract.can(Authority.EVIDENCE)
    assert not contract.can(Authority.APPROVE)
    assert not contract.can(Authority.PROVISION)


@pytest.mark.parametrize("provider", list(Provider))
def test_provider_cannot_approve_or_provision(provider):
    assert_provider_cannot_approve(provider)
    assert_provider_cannot_provision(provider)


def test_contract_rejects_forbidden_authority_configuration():
    contract = ProviderContract(provider=Provider.QWEN, authorities=frozenset({Authority.EXECUTE, Authority.APPROVE}))
    with pytest.raises(ValueError, match="PROVIDER_AUTHORITY_DENIED:APPROVE"):
        contract.validate()


def test_contract_rejects_provision_authority_configuration():
    contract = ProviderContract(provider=Provider.CLAUDE, authorities=frozenset({Authority.EXECUTE, Authority.PROVISION}))
    with pytest.raises(ValueError, match="PROVIDER_AUTHORITY_DENIED:PROVISION"):
        contract.validate()
