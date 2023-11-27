//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Event.sol";

contract Router is ConfirmedOwner {
    // totalEvents is mapped to totalClasses in the event. Used to then getEvent.
    uint256 public totalEvents;
    mapping(uint256 => uint256) public totalClasses;

    // eventIndex, eventClass, address
    mapping(uint256 => mapping(uint256 => address)) public getEvent;

    //add events
    //add mapping with event address to totalsupply limit, pricing, etc? Or read directly from event with view function?

    event newEventDeployed(
        uint256 eventIndex,
        uint256 classIndex,
        address eventAddress
    );

    constructor() ConfirmedOwner(msg.sender) {}

    function getEventAddress(
        uint256 eventIndex,
        uint256 eventClass
    ) public view returns (address) {
        return getEvent[eventIndex][eventClass];
    }

    function _addEventAddress(
        uint256 eventIndex,
        uint256 classIndex,
        address eventAddress
    ) internal {
        getEvent[eventIndex][classIndex] = eventAddress;
        emit newEventDeployed(eventIndex, classIndex, eventAddress);
    }

    function _incrementEvent(uint256 eventIndex) internal {
        totalEvents++;
        totalClasses[eventIndex]++;
    }

    function _incrementClass(uint256 eventIndex) internal {
        totalClasses[eventIndex]++;
    }

    //event index is incremented (new event), class is set to 0 (new event)
    // test removing the memory modifier
    function newEvent(
        string memory name,
        string memory symbol,
        address priceFeed
    ) public onlyOwner {
        //starts at 1
        uint256 eventIndex = totalEvents + 1;

        require(getEvent[eventIndex][0] == address(0), "Event already exists");

        address eventAddress = address(
            new Event(name, symbol, priceFeed, msg.sender, address(this))
        );

        //is there a counting concern here? Test
        _incrementEvent(eventIndex);
        _addEventAddress(eventIndex, 0, eventAddress);
    }

    // given an existing eventIndex, increment class for new NFT.
    //New contract, classified in the router under the same event.
    function newClass(
        string memory name,
        string memory symbol,
        address priceFeed,
        uint256 eventIndex
    ) public onlyOwner {
        uint256 classIndex = totalClasses[eventIndex] + 1;

        require(
            getEvent[eventIndex][classIndex] == address(0),
            "Event already exists"
        );
        require(eventIndex <= totalEvents, "Event does not exist yet");

        address eventAddress = address(
            new Event(name, symbol, priceFeed, msg.sender, address(this))
        );
        _incrementClass(eventIndex);
        _addEventAddress(eventIndex, classIndex, eventAddress);
    }

    function withdrawETH() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawToken(address tokenAddress, address to) public onlyOwner {
        IERC20 token = IERC20(tokenAddress);
        uint256 amount = token.balanceOf(address(this));
        token.transfer(to, amount);
    }

    // Fallback function must be declared as external.
    fallback() external payable {
        // send / transfer (forwards 2300 gas to this fallback function)
        // call (forwards all of the gas)
        //emit Log("fallback", gasleft());
    }

    // Receive is a variant of fallback that is triggered when msg.data is empty
    receive() external payable {
        //emit Log("receive", gasleft());
    }
}
