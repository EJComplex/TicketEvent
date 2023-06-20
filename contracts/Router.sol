//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

// Deploy router, deploy nfts, set router as owner of nfts, Handle pricing in nfts,
// router's purpose is to have one point of interaction for buying tickets and updating NFTs
// router can handle any number of NFT ticket events.
// router contains mappings/arrays? for tracking all event details (limits, pricing, URI, open/closed)
// router has

contract Event is ConfirmedOwner {
    constructor() ConfirmedOwner(msg.sender) {}

    function openTicket() public onlyOwner {}

    function updatePriceFeed() public onlyOwner {}

    function updateTokenPayment() public onlyOwner {}

    function updateEthPayment() public onlyOwner {}

    function withdrawEth() public onlyOwner {}

    function withdrawToken() public onlyOwner {}

    function setBaseURI() public onlyOwner {}

    function setTierURI() public onlyOwner {}

    function setTierPrice() public onlyOwner {}

    function setTicketLimit() public onlyOwner {}

    function balanceEth(address eventAddress) public view returns (uint256) {}

    function balanceToken(
        address eventAddress,
        address tokenAddress
    ) public view returns (uint256) {}
}
