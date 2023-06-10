from scripts.script_library import get_account, config
from brownie import Event
from web3 import Web3


# local
def main():
    account = get_account()
    depEvent = Event.deploy("Ticket Event", "STUB", {"from": account})

    tx1 = depEvent.openEvent({"from": account})

    tx2 = depEvent.setBaseURI("https://test.com/", {"from": account})

    for i in range(3):
        tx3 = depEvent.setClassURI(i, str(i))
        tx4 = depEvent.setClassLimit(i, 10)
        tx4 = depEvent.setClassPrice(i, i)

    tx5 = depEvent.buyTicket(1, 0, {"from": account})
    tx5.wait(1)
