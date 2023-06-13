from scripts.script_library import get_account, config
from brownie import Event, MockV3Aggregator
from web3 import Web3


def deployEvent(account, ticketName, ticketSymbol, priceFeed):
    depEvent = Event.deploy(ticketName, ticketSymbol, priceFeed, {"from": account})
    return depEvent


def configureEvent(account, eventContract):
    txList = []
    tx1 = eventContract.openEvent({"from": account})
    txList.append(tx1)

    tx2 = eventContract.setBaseURI("https://test.com/", {"from": account})
    txList.append(tx2)

    for i in range(3):
        tx3 = eventContract.setClassURI(i, str(i))
        tx4 = eventContract.setClassLimit(i, 10)
        # $50
        tx5 = eventContract.setClassPrice(i, Web3.toWei(50, "ether"))
        txList.extend([tx3, tx4, tx5])

    return txList


def buyTicket(account, eventContract, quantity=10, classType=0):
    value = Web3.toWei(1, "ether")
    tx = eventContract.buyTicket(quantity, classType, {"from": account, "value": value})
    return tx


def deployMock(account, decimals, initial_value):
    depMockV3 = MockV3Aggregator.deploy(decimals, initial_value, {"from": account})
    return depMockV3


# local
def main():
    account = get_account()

    # deploy mocks
    DECIMALS = 8
    INITIAL_VALUE = 200000000000
    depMockV3 = deployMock(account, DECIMALS, INITIAL_VALUE)

    ticketName = "Ticket Event"
    ticketSymbol = "STUB"
    depEvent = deployEvent(account, ticketName, ticketSymbol, depMockV3.address)

    configTxList = configureEvent(account, depEvent)

    txBuyTicket = buyTicket(account, depEvent)

    txBuyTicket.wait(1)
