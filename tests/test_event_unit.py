from scripts.script_library import get_account
from scripts.deploy import deployEvent, configureEvent, buyTicketEth, deployMock
from brownie import network, config, exceptions


from web3 import Web3
import pytest

# test deploy, config, mint ticket, mint multiple tickets, test mint limit, test transfer, URI info check,
# test all public variables and functions.
# create automated loop to read contract functions and variables and check their accessibility and values.


# test mint price,

# Fix tests, parameterize tests and functions, create tests for each function.

# configure price feeds
# test buying with tokens, limits, price, URI
# test withdrawl eth, tokens


# module wide deploy and mock.
@pytest.fixture(scope="module", autouse=True)
def default_deploy_configure():
    account = get_account()
    # deploy mocks
    DECIMALS = 8
    INITIAL_VALUE = 200000000000
    depMockV3 = deployMock(account, DECIMALS, INITIAL_VALUE)
    ticketName = "Test Event"
    ticketSymbol = "TEST"
    depEvent = deployEvent(account, ticketName, ticketSymbol, depMockV3.address)
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
    # deploy mocks
    DECIMALS = 8
    INITIAL_VALUE = 200000000000
    depMockV3 = deployMock(account, DECIMALS, INITIAL_VALUE)
    depEvent = deployEvent(account, ticketName, ticketSymbol, depMockV3)

    assert depEvent.name() == "Test Event"
    assert depEvent.symbol() == "TEST"


# open_event(), event_state, classURI ,classLimit ,classPrice
def test_configure():
    account = get_account()
    ticketName = "Test Event"
    ticketSymbol = "TEST"
    # deploy mocks
    DECIMALS = 8
    INITIAL_VALUE = 200000000000
    depMockV3 = deployMock(account, DECIMALS, INITIAL_VALUE)
    depEvent = deployEvent(account, ticketName, ticketSymbol, depMockV3)
    assert depEvent.event_state() == 1

    configTxList = configureEvent(account, depEvent)
    assert depEvent.event_state() == 0

    assert depEvent.classURI() == str("testA")
    assert depEvent.classLimit() == 10
    assert depEvent.classPrice() == Web3.toWei(50, "ether")


# buyTicket(), balanceOf(), tokenURI(), ownerOf(), Transfer Event
def test_buy_ticket_eth():
    account = get_account()
    ticketName = "Test Event"
    ticketSymbol = "TEST"
    # deploy mocks
    DECIMALS = 8
    INITIAL_VALUE = 200000000000
    depMockV3 = deployMock(account, DECIMALS, INITIAL_VALUE)
    depEvent = deployEvent(account, ticketName, ticketSymbol, depMockV3)

    configTxList = configureEvent(account, depEvent)
    assert depEvent.balanceOf(account) == 0

    txBuyTicket = buyTicketEth(account, depEvent, quantity=1)
    assert depEvent.balanceOf(account) == 1

    tokenId = txBuyTicket.events["Transfer"]["tokenId"]
    assert depEvent.tokenURI(tokenId) == "https://test.com/testA"

    assert depEvent.ownerOf(tokenId) == account.address


# buyTicket(),
def test_batch_buy_ticket_eth(default_deploy_configure):
    (account, depEvent) = default_deploy_configure

    txBuyTicket = buyTicketEth(account, depEvent, quantity=10)
    assert depEvent.balanceOf(account) == 10


def test_transfer(default_deploy_configure):
    (account, depEvent) = default_deploy_configure
    txBuyTicket = buyTicketEth(account, depEvent)
    tokenId = txBuyTicket.events["Transfer"]["tokenId"]
    assert tokenId == depEvent.tokenOfOwnerByIndex(account.address, 0)

    account2 = get_account(index=1)
    assert depEvent.balanceOf(account2.address) == 0
    txTransfer = depEvent.transferFrom(account.address, account2.address, tokenId)
    assert depEvent.balanceOf(account2.address) == 1


def test_ticket_limit(default_deploy_configure):
    (account, depEvent) = default_deploy_configure
    limit = depEvent.classLimit()
    with pytest.raises(exceptions.VirtualMachineError):
        txBuyTicket = buyTicketEth(account, depEvent, quantity=limit + 1)


def test_only_owner():
    account = get_account()
    ticketName = "Test Event"
    ticketSymbol = "TEST"
    # deploy mocks
    DECIMALS = 8
    INITIAL_VALUE = 200000000000
    depMockV3 = deployMock(account, DECIMALS, INITIAL_VALUE)
    depEvent = deployEvent(account, ticketName, ticketSymbol, depMockV3)
    account2 = get_account(index=1)
    with pytest.raises(exceptions.VirtualMachineError):
        txOpen = depEvent.openEvent({"from": account2})
