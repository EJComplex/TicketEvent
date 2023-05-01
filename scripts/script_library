from brownie import accounts, network, config, web3

FORKED_LOCAL_ENVIRONMENTS = ["mainnet-fork"]
LOCAL_BLOCKCHAIN_ENVIRONMENTS = ["development", "ganache-local"]
TESTNET_ENVIRONMENTS = ["sepolia"]


def get_account(index=None, id=None, unlock_index=None):
    # accounts[0]
    # accounts.add("env")
    # accounts.load("id")

    if index:
        return accounts[index]

    if id:
        return accounts.load(id)

    if unlock_index:
        account = accounts.at(
            config["networks"][network.show_active()]["cmd_settings"]["unlock"][
                unlock_index
            ]
        )
        return account

    if (
        network.show_active() in LOCAL_BLOCKCHAIN_ENVIRONMENTS
        or network.show_active() in FORKED_LOCAL_ENVIRONMENTS
    ):
        return accounts[0]

    return accounts.add(config["wallets"]["from_key"])
