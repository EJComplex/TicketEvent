from scripts.script_library import get_account, config
from brownie import Event
from web3 import Web3


def deployEvent(account, ticketName, ticketSymbol):
    depEvent = Event.deploy(ticketName, ticketSymbol, {"from": account})
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
        tx5 = eventContract.setClassPrice(i, i)
        txList.extend([tx3, tx4, tx5])

    return txList


def buyTicket(account, eventContract, quantity=1, classType=0):
    tx = eventContract.buyTicket(quantity, classType, {"from": account})
    return tx


# local
def main():
    account = get_account()
    ticketName = "Ticket Event"
    ticketSymbol = "STUB"
    depEvent = deployEvent(account, ticketName, ticketSymbol)
    print(depEvent.event_state())
    configTxList = configureEvent(account, depEvent)
    txBuyTicket = buyTicket(account, depEvent)

    txBuyTicket.wait(1)
