// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Event is ConfirmedOwner, ERC721URIStorage {


    constructor() 
        ConfirmedOwner(msg.sender)
        ERC721("TicketEvent","TICK") {}


    function addTicket() public {}

    function buyTicket() public {}

    
}