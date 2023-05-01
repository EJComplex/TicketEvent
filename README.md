Ticket Contract Spec - 

Factory Contract:
call functions in contract with specifications to mint event specific contract

Event Contract:
minted from factory contract. Contains parameters for event ticketing. Ticket NFTs can be minted according to parameters. 
Parameters: Pay with ETH/stablecoin/specific token. NFTs have art associated with them. Whitelisting for initial ticket sales. 

Long term:
Create front end to interact with factory contract.
Create front end to interact with Event Contaract.
Mix in Account Abstracted wallets for easy onboarding.

Considerations:
Use Chainlink price feed for price confirmation. Test subscription and ad hoc payment methods. Use RNG Chainlink for NFT FUN!
Once a working prototype is fully functional, build out testing suite to check security of contracts. Review gas optimization. Deploy on Arbitrum testnet.
Real world implementation may need to limit whitelisting to verified phone numbers, etc. Future may allow for onchain identity to filter as whitelist


