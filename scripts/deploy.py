from scripts.script_library import get_account, config
from brownie import Event, MockV3Aggregator, OurToken, Router
from web3 import Web3


def deployEvent(account, ticketName, ticketSymbol, priceFeed, router):
    depEvent = Event.deploy(
        ticketName, ticketSymbol, priceFeed, router, {"from": account}
    )
    return depEvent


def configureEvent(account, eventContract):
    txList = []
    tx1 = eventContract.openEvent({"from": account})
    txList.append(tx1)

    tx2 = eventContract.setBaseURI("https://test.com/", {"from": account})
    txList.append(tx2)

    tx3 = eventContract.setClassURI("testA")
    tx4 = eventContract.setClassLimit(10)
    # $50
    tx5 = eventContract.setClassPrice(Web3.toWei(50, "ether"))
    txList.extend([tx3, tx4, tx5])

    return txList


def buyTicketEth(account, eventContract, quantity=1):
    value = Web3.toWei(1, "ether")
    tx = eventContract.buyTicketEth(quantity, {"from": account, "value": value})
    return tx


def deployMock(account, decimals, initial_value):
    depMockV3 = MockV3Aggregator.deploy(decimals, initial_value, {"from": account})
    return depMockV3


def setTokenAddress(account, eventContract, tokenAddress, feedAddress):
    tx = eventContract.enableToken(tokenAddress, feedAddress, {"from": account})
    return tx


def buyTicketToken(account, eventContract, tokenAddress, quantity=1):
    value = Web3.toWei(1, "ether")
    tx = eventContract.buyTicketToken(quantity, tokenAddress, {"from": account})
    return tx


# local
def main():
    TEST = False
    if not TEST:
        account = get_account()

        # deploy mocks for ETH USD price feed
        DECIMALS = 8
        INITIAL_VALUE = 200000000000
        depMockV3 = deployMock(account, DECIMALS, INITIAL_VALUE)

        # deploy router
        router = Router.deploy({"from": account})

        # deploy Event
        ticketName = "Ticket Event"
        ticketSymbol = "STUB"
        # returns transaction hash
        depEvent = router.newEvent(
            ticketName, ticketSymbol, depMockV3.address, 4, 4, {"from": account}
        )
        eventAddress = depEvent.events["newEventDeployed"]["eventAddress"]

        depEventContract = Event.at(eventAddress)

        print(eventAddress)
        print(router.getEventAddress(4, 4, {"from": account}))
        depEvent.wait(1)

        # configTxList = configureEvent(account, depEvent)

        # txBuyTicket = buyTicketEth(account, depEvent)

        # # USDC mainnet feed
        # # usdcFeed = "0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6"
        # # usdcAddress = "0xa0b86991c6218b36c1d19d4a2e9eb0ce3606eb48"
        # testToken = OurToken.deploy(1000000000000000000000, {"from": account})

        # # deploy mocks for stable coin
        # DECIMALS = 8
        # INITIAL_VALUE = 100000000
        # depMockV3Token = deployMock(account, DECIMALS, INITIAL_VALUE)

        # txSet = setTokenAddress(
        #     account, depEvent, testToken.address, depMockV3Token.address
        # )

        # # approve
        # txApprove = testToken.approve(
        #     depEvent.address, 1000000000000000000000, {"from": account}
        # )

        # # account2 = get_account(index=1)

        # # txApprove = testToken.approve(account2, 1000000000000000000000, {"from": account})

        # # txTransferFrom = testToken.transferFrom(
        # #     account.address, account2.address, 50000000000000000000, {"from": account2}
        # # )

        # txBuyTicketToken = buyTicketToken(account, depEvent, testToken.address)

        # # txBuyTicketToken = depEvent.getTicketPriceToken(
        # #     testToken.address, {"from": account}
        # # )
        # # print(txBuyTicketToken)

        # txBuyTicketToken.wait(1)
        # # txApprove.wait(1)
    else:
        account = get_account()
        router = Router.deploy({"from": account})
        tx = router.newEvent({"from": account})

        event = Event.deploy(
            "Test",
            "TST",
            "0x8fFfFfd4AfB6115b954Bd326cbe7B4BA576818f6",
            account.address,
            {"from": account},
        )

        tx.wait(1)
