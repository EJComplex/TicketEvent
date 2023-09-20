from scripts.script_library import get_account
from scripts.deploy import (
    deployEvent,
    configureEvent,
    buyTicketEth,
    deployMock,
    deployRouter,
    deployClass,
    buyTicketToken,
)
from brownie import network, config, exceptions, OurToken


from web3 import Web3
import pytest
from decimal import *

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

    # Mock Dai feed. Pay attention to decimals

    ticketName = "Test Event"
    ticketSymbol = "TEST"
    depRouter = deployRouter(account)
    # mock EthUSD price feed
    txUpdateEthPriceFeed = depRouter.updateEthPriceFeed(depMockV3.address)
    # mainnet DaiUSD price feed
    # txUpdateDaiPriceFeed = depRouter.updateTokenPriceFeed(
    #     "0x6b175474e89094c44da98b954eedeac495271d0f",
    #     "0xaed0c38402a5d19df6e4c03f4e2dced6e29c1ee9",
    # )

    depEvent = deployEvent(
        account, ticketName, ticketSymbol, depMockV3.address, depRouter
    )

    DECIMALS = 10
    INITIAL_VALUE = 10000000000
    depMockV3Token = deployMock(account, DECIMALS, INITIAL_VALUE)

    TT = OurToken.deploy(1000000000000000, {"from": account})

    txUpdateTokenPriceFeed = depEvent.enableToken(
        TT.address, depMockV3Token.address, {"from": account}
    )

    configTxList = configureEvent(account, depEvent)

    return account, depRouter, depEvent, depMockV3, depMockV3Token, TT


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
    depRouter = deployRouter(account)
    depEvent = deployEvent(account, ticketName, ticketSymbol, depMockV3, depRouter)

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
    depRouter = deployRouter(account)
    depEvent = deployEvent(account, ticketName, ticketSymbol, depMockV3, depRouter)
    assert depEvent.event_state() == 1

    configTxList = configureEvent(account, depEvent)
    assert depEvent.event_state() == 0

    assert depEvent.classURI() == str("testA")
    assert depEvent.classLimit() == 10
    assert depEvent.classPrice() == Web3.toWei(50, "ether")

    # test closing
    txClose = depEvent.closeEvent({"from": account})
    assert depEvent.event_state() == 1


def test_buy_ticket_eth(default_deploy_configure):
    (
        account,
        depRouter,
        depEvent,
        depMockV3,
        depMockV3Token,
        TT,
    ) = default_deploy_configure
    # account = get_account()
    # ticketName = "Test Event"
    # ticketSymbol = "TEST"
    # # deploy mocks
    # DECIMALS = 8
    # INITIAL_VALUE = 200000000000
    # depMockV3 = deployMock(account, DECIMALS, INITIAL_VALUE)
    # depRouter = deployRouter(account)
    # depEvent = deployEvent(account, ticketName, ticketSymbol, depMockV3, depRouter)

    # configTxList = configureEvent(account, depEvent)

    assert depEvent.balanceOf(account) == 0

    txBuyTicket = buyTicketEth(account, depEvent, quantity=1)
    assert depEvent.balanceOf(account) == 1

    tokenId = txBuyTicket.events["Transfer"][0]["tokenId"]
    assert depEvent.tokenURI(tokenId) == "https://test.com/testA"

    assert depEvent.ownerOf(tokenId) == account.address


def test_buy_ticket_token(default_deploy_configure):
    (
        account,
        depRouter,
        depEvent,
        depMockV3,
        depMockV3Token,
        TT,
    ) = default_deploy_configure

    assert depEvent.balanceOf(account) == 0

    txBuyTicket = buyTicketToken(account, depEvent, TT, quantity=1)
    assert depEvent.balanceOf(account) == 1

    tokenId = txBuyTicket.events["Transfer"][1]["tokenId"]
    assert depEvent.tokenURI(tokenId) == "https://test.com/testA"

    assert depEvent.ownerOf(tokenId) == account.address


def test_batch_buy_ticket_eth(default_deploy_configure):
    (
        account,
        depRouter,
        depEvent,
        depMockV3,
        depMockV3Token,
        TT,
    ) = default_deploy_configure

    txBuyTicket = buyTicketEth(account, depEvent, quantity=10)
    assert depEvent.balanceOf(account) == 10


# def test_burn(default_deploy_configure):
#     (account, depRouter, depEvent, depMockV3, depMockV3Token, TT) = default_deploy_configure


def test_transfer(default_deploy_configure):
    (
        account,
        depRouter,
        depEvent,
        depMockV3,
        depMockV3Token,
        TT,
    ) = default_deploy_configure
    txBuyTicket = buyTicketEth(account, depEvent)
    tokenId = txBuyTicket.events["Transfer"]["tokenId"]
    assert tokenId == depEvent.tokenOfOwnerByIndex(account.address, 0)

    account2 = get_account(index=1)
    assert depEvent.balanceOf(account2.address) == 0
    txTransfer = depEvent.transferFrom(
        account.address, account2.address, tokenId, {"from": account}
    )
    assert depEvent.balanceOf(account2.address) == 1
    assert depEvent.balanceOf(account.address) == 0


def test_ticket_limit(default_deploy_configure):
    (
        account,
        depRouter,
        depEvent,
        depMockV3,
        depMockV3Token,
        TT,
    ) = default_deploy_configure
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
    depRouter = deployRouter(account)
    depEvent = deployEvent(account, ticketName, ticketSymbol, depMockV3, depRouter)
    account2 = get_account(index=1)
    with pytest.raises(exceptions.VirtualMachineError):
        txOpen = depEvent.openEvent({"from": account2})


def test_count_event_logic(default_deploy_configure):
    (
        account,
        depRouter,
        depEvent,
        depMockV3,
        depMockV3Token,
        TT,
    ) = default_deploy_configure
    assert depRouter.totalEvents() == 1
    ticketName = "ticket2"
    ticketSymbol = "TK"
    depEvent2 = deployEvent(
        account, ticketName, ticketSymbol, depMockV3.address, depRouter
    )
    assert depRouter.totalEvents() == 2


def test_count_class_logic(default_deploy_configure):
    (
        account,
        depRouter,
        depEvent,
        depMockV3,
        depMockV3Token,
        TT,
    ) = default_deploy_configure
    assert depRouter.totalClasses(0) == 0
    assert depRouter.totalClasses(1) == 1
    ticketName = "ticket2"
    ticketSymbol = "TK"
    depClass2 = deployClass(account, ticketName, ticketSymbol, depMockV3, depRouter, 1)
    assert depRouter.totalClasses(1) == 2

    with pytest.raises(exceptions.VirtualMachineError):
        depClass3 = deployClass(
            account, ticketName, ticketSymbol, depMockV3, depRouter, 2
        )


def test_event_pricefeed(default_deploy_configure):
    (
        account,
        depRouter,
        depEvent,
        depMockV3,
        depMockV3Token,
        TT,
    ) = default_deploy_configure
    # Initial value of $2000 Ether. Test $50 entry price
    ethCost = depEvent.getTicketPriceEth({"from": account})
    assert (Web3.fromWei(ethCost, "ether") - Decimal(0.025)) / Decimal(0.025) < 0.001

    depEvent.setClassPrice(Web3.toWei(100, "ether"), {"from": account})
    ethCost = depEvent.getTicketPriceEth({"from": account})
    assert (Web3.fromWei(ethCost, "ether") - Decimal(0.05)) / Decimal(0.05) < 0.001


def test_remaining_count(default_deploy_configure):
    (
        account,
        depRouter,
        depEvent,
        depMockV3,
        depMockV3Token,
        TT,
    ) = default_deploy_configure

    assert depEvent.remainingCount({"from": account}) == 10
    txBuyTickets = buyTicketEth(account, depEvent, quantity=6)
    assert depEvent.remainingCount({"from": account}) == 4


def test_withdraw_eth(default_deploy_configure):
    (
        account,
        depRouter,
        depEvent,
        depMockV3,
        depMockV3Token,
        TT,
    ) = default_deploy_configure
    txBuyTickets = buyTicketEth(account, depEvent, quantity=6)

    startBalanceAccount = account.balance()
    startBalanceEvent = depEvent.balance()
    txWithdraw = depEvent.withdrawETH({"from": account})

    assert depEvent.balance() == 0
    assert (account.balance() - startBalanceAccount) == startBalanceEvent
