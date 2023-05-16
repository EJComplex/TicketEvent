// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";


contract EventFactory is ConfirmedOwner { 

//

constructor() ConfirmedOwner(msg.sender) {}


function createEvent() external {

}


}