// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

// Simple. Can mint from 3 ranges of tickets, with 3 different prices. Ticket type is defined by the tokenId being in the defined range.
// Not addTicket(). Instead just limit mint based on constants/variables defined in the contract
// Implement payment with ETH, then with select tokens
// add function to update price feed
//
// 3 separate NFT contracts for the 3 levels. Or a dynamic NFT with a modular amount of levels???
//
// deploy on mainnet testnet. deploy on arbitrum testnet.
// may allow for abi encoded/ other method of purchasing multiple type of tickets at once

contract Event is ConfirmedOwner, ERC721URIStorage, ERC721Enumerable {
    // Base URI
    string private _baseStringURI;

    // Price Feed
    AggregatorV3Interface internal ethUsdPriceFeed;

    // State
    enum EVENT_STATE {
        OPEN,
        CLOSED
    }
    EVENT_STATE public event_state;

    // Class mappings, URI, Count Limit, Price
    mapping(uint256 => string) public classURI;
    mapping(uint256 => uint256) public classLimit;
    mapping(uint256 => uint256) public classPrice;

    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        address _priceFeedAddress
    ) ConfirmedOwner(msg.sender) ERC721(tokenName, tokenSymbol) {
        event_state = EVENT_STATE.CLOSED;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
    }

    function openEvent() public onlyOwner {
        event_state = EVENT_STATE.OPEN;
    }

    function updatePriceFeed(address _newPriceFeed) public onlyOwner {
        ethUsdPriceFeed = AggregatorV3Interface(_newPriceFeed);
    }

    function getTicketPrice(uint256 class) public view returns (uint256) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10 ** 10; //18 decimals
        uint256 costTicket = (classPrice[class] * 10 ** 18) / adjustedPrice;
        return costTicket;
    }

    // function to buy x number of one class of ticket
    // Example for TicketA
    function buyTicket(uint256 numberOfTickets, uint256 class) public payable {
        require(event_state == EVENT_STATE.OPEN, "Event is not open!");
        require(
            (msg.value) >= (getTicketPrice(class) * numberOfTickets),
            "Not enough ETH!"
        );

        uint256 ticketLimit = classLimit[class];
        //limit number of tickets at once
        require(
            (totalSupply() + numberOfTickets) <= ticketLimit,
            "Purchase would exceed max supply of Ticket A"
        );

        //mintIndex does not define the ticket type. URI Storage does.
        //define A,B,C Base tokenURIs.
        //when ticket is minted, set unique tokenURI ending.
        //
        for (uint256 i = 0; i < numberOfTickets; i++) {
            uint256 mintIndex = totalSupply();
            string memory ticketURI = classURI[class];
            if (totalSupply() < ticketLimit) {
                _safeMint(msg.sender, mintIndex);
                _setTokenURI(mintIndex, ticketURI);
            }
        }
    }

    // add public view functions to determine remaining tickets of each class

    function withdrawETH() public onlyOwner {
        uint256 balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawToken() public onlyOwner {}

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setClassURI(uint256 class, string memory value) public onlyOwner {
        _setClassURI(class, value);
    }

    function setClassLimit(uint256 class, uint256 value) public onlyOwner {
        _setClassLimit(class, value);
    }

    function setClassPrice(uint256 class, uint256 value) public onlyOwner {
        _setClassPrice(class, value);
    }

    function _setClassURI(uint256 class, string memory value) internal {
        classURI[class] = value;
    }

    function _setClassLimit(uint256 class, uint256 value) internal {
        classLimit[class] = value;
    }

    function _setClassPrice(uint256 class, uint256 value) internal {
        classPrice[class] = value;
    }

    function _setBaseURI(string memory baseURI_) internal {
        _baseStringURI = baseURI_;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseStringURI;
    }

    /**
     * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal override(ERC721, ERC721Enumerable) {
        ERC721Enumerable._beforeTokenTransfer(
            from,
            to,
            firstTokenId,
            batchSize
        );
    }

    /**
     * @dev See {ERC721-_burn}. This override additionally checks to see if a
     * token-specific URI was set for the token, and if so, it deletes the token URI from
     * the storage mapping.
     */
    function _burn(
        uint256 tokenId
    ) internal override(ERC721, ERC721URIStorage) {
        ERC721URIStorage._burn(tokenId);
    }

    /**
     * @dev See {IERC165-supportsInterface}
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view override(ERC721, ERC721Enumerable) returns (bool) {
        return ERC721Enumerable.supportsInterface(interfaceId);
    }

    /**
     * @dev See {IERC721Metadata-tokenURI}.
     */
    function tokenURI(
        uint256 tokenId
    ) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return ERC721URIStorage.tokenURI(tokenId);
    }
}
