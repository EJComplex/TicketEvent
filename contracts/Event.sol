//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@chainlink/contracts/src/v0.8/ConfirmedOwner.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Event is ConfirmedOwner, ERC721URIStorage, ERC721Enumerable {
    address private _router;

    string private _baseStringURI;

    AggregatorV3Interface internal ethUsdPriceFeed;

    enum EVENT_STATE {
        OPEN,
        CLOSED
    }
    EVENT_STATE public event_state;

    string public classURI;
    uint256 public classLimit;
    uint256 public classPrice;

    mapping(address => address) tokenToPriceFeed;

    //update owner to be routing contract?
    constructor(
        string memory tokenName,
        string memory tokenSymbol,
        address _priceFeedAddress,
        address _owner,
        address _routerAddress
    ) ConfirmedOwner(_owner) ERC721(tokenName, tokenSymbol) {
        event_state = EVENT_STATE.CLOSED;
        ethUsdPriceFeed = AggregatorV3Interface(_priceFeedAddress);
        _router = _routerAddress;
    }

    function openEvent() public onlyOwner {
        event_state = EVENT_STATE.OPEN;
    }

    function closeEvent() public onlyOwner {
        event_state = EVENT_STATE.CLOSED;
    }

    function updatePriceFeed(address _newPriceFeed) public onlyOwner {
        ethUsdPriceFeed = AggregatorV3Interface(_newPriceFeed);
    }

    function getTicketPriceEth() public view returns (uint256 costTicket) {
        (, int256 price, , , ) = ethUsdPriceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10 ** 10; //18 decimals
        costTicket = (classPrice * 10 ** 18) / adjustedPrice;
    }

    //confirm decimals for token
    function getTicketPriceToken(
        address tokenAddress
    ) public view returns (uint256 costTicket) {
        require(
            tokenToPriceFeed[tokenAddress] != address(0),
            "Token address not enabled"
        );
        AggregatorV3Interface priceFeed = AggregatorV3Interface(
            tokenToPriceFeed[tokenAddress]
        );
        (, int256 price, , , ) = priceFeed.latestRoundData();
        uint256 adjustedPrice = uint256(price) * 10 ** 10; //18 decimals. THIS WILL CHANGE FOR DIFFERENT TOKENS
        costTicket = (classPrice * 10 ** 18) / adjustedPrice;
    }

    function enableToken(address tokenAddress, address feed) public onlyOwner {
        tokenToPriceFeed[tokenAddress] = feed;
    }

    function disableToken(address tokenAddress) public onlyOwner {
        tokenToPriceFeed[tokenAddress] = address(0);
    }

    // function to buy x number of one class of ticket
    function buyTicketEth(uint256 numberOfTickets) public payable {
        require(event_state == EVENT_STATE.OPEN, "Event is not open!");
        require(
            (msg.value) >= (getTicketPriceEth() * numberOfTickets),
            "Not enough ETH!"
        );

        //limit number of tickets at once
        require(
            (totalSupply() + numberOfTickets) <= classLimit,
            "Purchase would exceed max supply"
        );

        for (uint256 i = 0; i < numberOfTickets; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < classLimit) {
                _safeMint(msg.sender, mintIndex);
                _setTokenURI(mintIndex, classURI);
            }
        }
    }

    // function to buy x number of one class of ticket
    function buyTicketToken(
        uint256 numberOfTickets,
        address tokenAddress
    ) public {
        require(event_state == EVENT_STATE.OPEN, "Event is not open!");
        require(
            tokenToPriceFeed[tokenAddress] != address(0),
            "Token is not valid payment."
        );

        //limit number of tickets at once
        require(
            (totalSupply() + numberOfTickets) <= classLimit,
            "Purchase would exceed max supply"
        );

        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(
            msg.sender,
            address(this),
            getTicketPriceToken(tokenAddress) * numberOfTickets
        );

        for (uint256 i = 0; i < numberOfTickets; i++) {
            uint256 mintIndex = totalSupply();
            if (totalSupply() < classLimit) {
                _safeMint(msg.sender, mintIndex);
                _setTokenURI(mintIndex, classURI);
            }
        }
    }

    function remainingCount() public view returns (uint256 remaining) {
        remaining = classLimit - totalSupply();
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

    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }

    function setClassURI(string memory value) public onlyOwner {
        _setClassURI(value);
    }

    function setClassLimit(uint256 value) public onlyOwner {
        _setClassLimit(value);
    }

    function setClassPrice(uint256 value) public onlyOwner {
        _setClassPrice(value);
    }

    function _setClassURI(string memory value) internal {
        classURI = value;
    }

    function _setClassLimit(uint256 value) internal {
        classLimit = value;
    }

    function _setClassPrice(uint256 value) internal {
        classPrice = value;
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
