from scripts.script_library import get_account
from scripts.deploy import deployEvent, configureEvent, buyTicket
from brownie import network, config, exceptions


from web3 import Web3
import pytest

# test deploy, config, mint ticket, mint multiple tickets, test mint limit, test transfer, URI info check,
# test all public variables and functions.
# create automated loop to read contract functions and variables and check their accessibility and values.


# test mint price,


# module wide deploy and mock.
@pytest.fixture(scope="module", autouse=True)
def default_deploy_configure():
    account = get_account()
    ticketName = "Test Event"
    ticketSymbol = "TEST"
    depEvent = deployEvent(account, ticketName, ticketSymbol)
    configTxList = configureEvent(account, depEvent)

    return account, depEvent


@pytest.fixture(autouse=True)
def isolation(fn_isolation):
    pass


# constructor(), name(), symbol()
def test_deploy():
    account = get_account()
    ticketName = "Test Event"
    ticketSymbol = "TEST"
    depEvent = deployEvent(account, ticketName, ticketSymbol)

    assert depEvent.name() == "Test Event"
    assert depEvent.symbol() == "TEST"


# open_event(), event_state, classURI ,classLimit ,classPrice
def test_configure():
    account = get_account()
    ticketName = "Test Event"
    ticketSymbol = "TEST"
    depEvent = deployEvent(account, ticketName, ticketSymbol)
    assert depEvent.event_state() == 1

    configTxList = configureEvent(account, depEvent)
    assert depEvent.event_state() == 0

    for i in range(3):
        assert depEvent.classURI(i) == str(i)
        assert depEvent.classLimit(i) == 10
        assert depEvent.classPrice(i) == i


# buyTicket(), balanceOf(), tokenURI(), ownerOf(), Transfer Event
def test_buy_ticket():
    account = get_account()
    ticketName = "Test Event"
    ticketSymbol = "TEST"
    depEvent = deployEvent(account, ticketName, ticketSymbol)
    configTxList = configureEvent(account, depEvent)
    assert depEvent.balanceOf(account) == 0

    txBuyTicket = buyTicket(account, depEvent)
    assert depEvent.balanceOf(account) == 1

    tokenId = txBuyTicket.events["Transfer"]["tokenId"]
    assert depEvent.tokenURI(tokenId) == "https://test.com/0"

    assert depEvent.ownerOf(tokenId) == account.address


# buyTicket(),
def test_batch_buy_ticket(default_deploy_configure):
    (account, depEvent) = default_deploy_configure

    txBuyTicket = buyTicket(account, depEvent, quantity=10)
    assert depEvent.balanceOf(account) == 10


def test_transfer(default_deploy_configure):
    (account, depEvent) = default_deploy_configure
    txBuyTicket = buyTicket(account, depEvent)
    tokenId = txBuyTicket.events["Transfer"]["tokenId"]
    assert tokenId == depEvent.tokenOfOwnerByIndex(account.address, 0)

    account2 = get_account(index=1)
    assert depEvent.balanceOf(account2.address) == 0
    txTransfer = depEvent.transferFrom(account.address, account2.address, tokenId)
    assert depEvent.balanceOf(account2.address) == 1


def test_ticket_limit(default_deploy_configure):
    (account, depEvent) = default_deploy_configure
    limit = depEvent.classLimit(0)
    with pytest.raises(exceptions.VirtualMachineError):
        txBuyTicket = buyTicket(account, depEvent, quantity=limit + 1, classType=0)


def test_only_owner():
    account = get_account()
    ticketName = "Test Event"
    ticketSymbol = "TEST"
    depEvent = deployEvent(account, ticketName, ticketSymbol)
    account2 = get_account(index=1)
    with pytest.raises(exceptions.VirtualMachineError):
        txOpen = depEvent.openEvent({"from": account2})
