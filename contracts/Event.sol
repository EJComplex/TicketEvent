// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";

// Simple. Can mint from 3 ranges of tickets, with 3 different prices. Ticket type is defined by the tokenId being in the defined range.
// Not addTicket(). Instead just limit mint based on constants/variables defined in the contract
// Implement payment with ETH, then with select tokens
//
// 3 separate NFT contracts for the 3 levels. Or a dynamic NFT with a modular amount of levels???
//
// deploy on mainnet testnet. deploy on arbitrum testnet.
// may allow for abi encoded/ other method of purchasing multiple type of tickets at once

contract Event is ConfirmedOwner, ERC721URIStorage, ERC721Enumerable {
    // Base URI
    string private _baseStringURI;

    //uint256 private _tokenLimitA;
    //uint256 private _tokenLimitB;
    //uint256 private _tokenLimitC;

    enum EVENT_STATE {
        OPEN,
        CLOSED
    }

    EVENT_STATE public event_state;

    // USD. Price feed determines ETH equivalent
    //uint256 private _priceA;
    //uint256 private _priceB;
    //uint256 private _priceC;

    //ticketLimit cannot exceed _tokenLimit
    //uint256 public ticketLimitA;
    //uint256 public ticketLimitB;
    //uint256 public ticketLimitC;

    mapping(uint256 => string) public classURI;
    mapping(uint256 => uint256) public classLimit;
    mapping(uint256 => uint256) public classPrice;

    constructor(
        string memory tokenName,
        string memory tokenSymbol
    ) ConfirmedOwner(msg.sender) ERC721(tokenName, tokenSymbol) {
        event_state = EVENT_STATE.CLOSED;
    }

    function openEvent() public onlyOwner {
        event_state = EVENT_STATE.OPEN;
    }

    // function to buy x number of one class of ticket
    // Example for TicketA
    function buyTicket(uint256 numberOfTickets, uint256 class) public payable {
        require(event_state == EVENT_STATE.OPEN, "Event is not open!");
        uint256 ticketLimit = classLimit[class];
        //limit number of tickets at once
        require(
            (totalSupply() + numberOfTickets) <= ticketLimit,
            "Purchase would exceed max supply of Ticket A"
        );
        //require x amount of ETH/Token

        //mintIndex does not define the ticket type. URI Storage does.
        //define A,B,C Base tokenURIs.
        //when ticket is minted, set unique tokenURI ending.
        //
        for (uint256 i = 0; i < numberOfTickets; i++) {
            //define totalSupply for ticketA
            uint256 mintIndex = totalSupply();
            string memory ticketURI = classURI[class];
            if (totalSupply() < ticketLimit) {
                _safeMint(msg.sender, mintIndex);

                _setTokenURI(mintIndex, ticketURI);
            }
        }
    }

    function withdrawETH() public onlyOwner {
        uint balance = address(this).balance;
        payable(msg.sender).transfer(balance);
    }

    function withdrawToken() public onlyOwner {}

    function _baseURI() internal view override returns (string memory) {
        return _baseStringURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function _setBaseURI(string memory baseURI_) internal {
        _baseStringURI = baseURI_;
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
