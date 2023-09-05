//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./Event.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Router is ConfirmedOwner {
    mapping(address => address) tokenToPriceFeed;
    AggregatorV3Interface internal ethUsdPriceFeed;

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

    function updateEthPriceFeed(address _newPriceFeed) public onlyOwner {
        ethUsdPriceFeed = AggregatorV3Interface(_newPriceFeed);
    }

    function updateTokenPriceFeed(
        address _tokenAddress,
        address _newPriceFeed
    ) public onlyOwner {
        tokenToPriceFeed[_tokenAddress] = _newPriceFeed;
        //tokenToPriceFeed[_tokenAddress] = AggregatorV3Interface(_newPriceFeed);
    }

    // function getTicketPriceEth(
    //     uint256 classPrice
    // ) public view returns (uint256 costTicket) {
    //     (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
    //     uint256 adjustedPrice = uint256(price) * 10 ** 10; //18 decimals
    //     costTicket = (classPrice * 10 ** 18) / adjustedPrice;
    // }

    // //confirm decimals for token. Not all tokens have the same decimals. Confirm this is token USD price feed
    // function getTicketPriceToken(
    //     address tokenAddress,
    //     uint256 classPrice
    // ) public view returns (uint256 costTicket) {
    //     require(
    //         tokenToPriceFeed[tokenAddress] != address(0),
    //         "Token address not enabled"
    //     );
    //     AggregatorV3Interface priceFeed = AggregatorV3Interface(
    //         tokenToPriceFeed[tokenAddress]
    //     );
    //     (, int256 price, , , ) = priceFeed.latestRoundData();
    //     uint256 adjustedPrice = uint256(price) * 10 ** 10; //18 decimals
    //     costTicket = (classPrice * 10 ** 18) / adjustedPrice;
    // }

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
}
