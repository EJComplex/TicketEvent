//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Event.sol";

// Deploy router, deploy nfts, set router as owner of nfts, Handle pricing in nfts,
// router's purpose is to have one point of interaction for buying tickets and updating NFTs
// router can handle any number of NFT ticket events.
// router contains mappings/arrays? for tracking all event details (limits, pricing, URI, open/closed)
// router has
// Initially deploy NFTs separately and declare Router as owner. Maybe change to be similar to Uniswap Factory contract, self deploy.
// when deployed NFT add contract address to router, done manually until self deploy added.

//gas savings by declaring returned variable instead of writing return at the end.
//below example 21559 -> 21554 gas!
// function foo(uint256 input) public returns (uint256 number) {
//     number = 100 * input;
//     // TODO rest of your function
// }

contract Router is ConfirmedOwner {
    // eventIndex, eventClass, address
    mapping(uint256 => mapping(uint256 => address)) public getEvent;

    constructor() ConfirmedOwner(msg.sender) {}

    function addMapping(
        uint256 eventIndex,
        uint256 eventClass
    ) public view returns (address) {
        return getEvent[eventIndex][eventClass];
    }
}
