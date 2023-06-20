Ticket Contract Spec - 

Updated: X number of NFT contracts deployed, closed.
Router contract deployed. Router contract owns nft contracts. Router contract is owned.
Open each Event using router, configure with router, buy tickets through router, withdraw funds with router.


Ticket contract is ERC721 with extensions like metadata, enumerable? ERC721PresetMinterPauserAutoId? wrapper?, pausable, 
Mint contract inherits from ERC721, ownable. Mint contract defines whitelisting, defines venue ticket arrangement, minting. use price oracle for payment.
How to create different tiers of NFT? mint 0-1000 for $100. mint 1001-10000 for $50, etc.
Initially make Entire contract deployed from external account. Then parametrize it for deployment from on chain contract.


###################################
Factory Contract:
call functions in contract with specifications to mint event specific contract (ERC721 with defined specs)

Event Contract (ERC721):
minted from factory contract. Contains parameters for event ticketing (token URI). Ticket NFTs (TokenID) can be minted according to parameters. 
Parameters: Pay with ETH/stablecoin/specific token. NFTs have art associated with them. Whitelisting for initial ticket sales. 

Long term:
Create front end to interact with factory contract.
Create front end to interact with Event Contaract.
Mix in Account Abstracted wallets for easy onboarding.

Considerations:
Use Chainlink price feed for price confirmation. Test subscription and ad hoc payment methods. Use RNG Chainlink for NFT FUN!
Once a working prototype is fully functional, build out testing suite to check security of contracts. Review gas optimization. Deploy on Arbitrum testnet.
Real world implementation may need to limit whitelisting to verified phone numbers, etc. Future may allow for onchain identity to filter as whitelist

Security check number overflows, invalid inputs


Event details:
ticket mapping {unique ticket:price}, {seating location:price}
confirmedowner, msg.sender
Enum to track status of Event (Closed, Open, ..., closed)

ticket mapping types: exact seat to price, seating region to price.

To populate event ticket data, may need to do many individual calls similar to NFT "setTokenURI"


Understand ERC721 Implementation and what will need to be changed for ticketed events.

Factory contract creates NFT contract with certain specs. NFT contract then mints all tokens to self. Function allows for tickets to be transferred to user.


ERC 721 Notes:
User contract should implement IERC721Receiver to implement safeTransfers - Set up test example for correct and incorrect IERC721 Implement

Take notes meticulously on ERC721:
https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol

Import interfaces to be used in following functions.

Import utils/Address.sol
function isContract() account.code.length>0. Not a perfect way of checking if address is a contract since it can be circumvented with contract construction/destruction.
function sendValue() replaces transfer. reverts with errors. sendValue fixes an issue with EIP1884. Not sure how all available gas is fowrarded???
https://www.alchemy.com/overviews/solidity-call#:~:text=The%20call%20function%20in%20Solidity,contract%20from%20your%20own%20contract.
Call functions should be used when interacting with other smart contracts.
#### Review later. Fallback functions and calls. Static call, delegate call
function functionCall() 
function verifyCallResultFromTarget()
function verifyCallResult()
function _revert()

Import utils/Context.sol
function _msgSender()
function _msgData()
above functions used for intermediate, library like contracts. This is to provide sender and transaction data when from the application's point of view the account sending and paying for execution are not the actual sender. "Meta-transactions"

Import utils/Strings.sol
Import math/Math.sol
@dev Standard math utilities missing in the Solidity language.
functions: max, min, average, ceilDiv (rounds up after division), mulDiv Calculates floor(x * y / denominator) with full precision. Throws if result overflows a uint256 or denominator == 0, mulDiv with rounding, sqrt, log2,log10, log256
Import math/SignedMath.sol
functions min, max, average, abs

String functions 
toString() Converts a `uint256` to its ASCII `string` decimal representation.
toString() @dev Converts a `int256` to its ASCII `string` decimal representation.
toHexString() Converts a `uint256` to its ASCII `string` hexadecimal representation.
toHexString() Converts a `uint256` to its ASCII `string` hexadecimal representation with fixed length
toHexString() Converts an `address` with fixed length of 20 bytes to its not checksummed ASCII `string` hexadecimal representation.
equal() Returns true if the two strings are equal.

Import utils/introspection/ERC165.sol
function supportsInterface(bytes4 interfaceId) Implementation of the {IERC165} interface.


https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC721/ERC721.sol

Implementation of ERC721.

Contract inherits from Context, ERC165, IERC721 and IERC721Metadata.

keyword: "using". Defines custom library for Address and Strings

string private _name; Define token name
string private _symbol; Define token symbol
mapping(uint256 => address) private _owners; Token ID to owner address
mapping(address => uint256) private _balances; owner address to token count
mapping(uint256 => address) private _tokenApprovals; token ID to approved address
### not sure what operator approvals are?
mapping(address => mapping(address => bool)) private _operatorApprovals; owner address to operator approvals

Constructor initializes the Name and Symbol

Functions:
supportsInterface(bytes4 interfaceId)
    ERC-165 and IERC-165 override. Public View. External account or other contract can call function with input of interfaceId. If the interfaceId matches IERC721, IERC721Metadata, or IERC165 returns True. Those are the interfaces of the contract.
balanceOf(address owner)
    public view, reverts if owner is zero address. returns _balances[owner]. Mapping of address to uint256
ownerOf(uint256 tokenId)
    public view, owner address from _ownerOf(tokenId). Must not zero address. return owner address
name()
    public view, returns token name.
symbol()
    public view, returns token symbol.
tokenURI(uint256 tokenId)
    public view, calls _requiredMinted(). creates, string memory baseURI = _baseURI(). if bytes(baseURE).length >0, return string concat between base and tokenId
_baseURI()
    public view, returns base URI. empty by default.
approve(address to, uint256 tokenId)
    public, address owner = ERC721.ownerOf(tokenId). ERC721 is explicitly called here? to is required to not be the same as owner. Require _msgSender() == owner or is approved operator. calls _approve(to, tokenId)
getApproved(uint256 tokenId)
    public view, require tokenId is minted, returns mapping tokenId->uint256
setApprovalForAll(address operator, bool approved)
    public, calls _setApprovalForAll(). Again, when msg.sender is normally called _msgSender is called instead to be more robust and secure.
isApprovedForAll(address owner, address operator)
    public view, returns bool from mapping _operatorApprovals[owner][operator]
transferFrom(address from, address to, uint256 tokenId)
    public, requires approval or operator, calls _transfer()
safeTransferFrom(address from, address to, uint256 tokenId)
    public, calls safeTransferFrom with "" as calldata.
safeTransferFrom(address from, address to, uint256 tokenId, bytes memory data)
    public, require approved or owner. calls _safeTransfer. 
 _safeTransfer(address from, address to, uint256 tokenId, bytes memory data)
    internal, calls _transfer, requires _checkOnERC721Receiver
 _ownerOf(uint256 tokenId)
    internal view, returns mapping _owners[tokeId]
 _exists(uint256 tokenId)
    internal view, returns true if _ownerOf(tokenId) != zero address
 _isApprovedOrOwner(address spender, uint256 tokenId)
    internal view, owner is ERC721.ownerOf(tokenId). True if spender == owner, is approved operator, or approved.
 _safeMint(address to, uint256 tokenId)
    internal, calls _safemint with calldata ""
 _safeMint(address to, uint256 tokenId, bytes memory data)
    internal, calls _mint, requires _checkOnERC721Recieved
 _mint(address to, uint256 tokenId)
    internal, requires to not zero address, requires tokenId not to exist. calls _beforeTokenTransfer(address(0), to, tokenId, 1). require tokenId not to exist, again. unchecked increment of _balances, set _owners[tokenId] = to, emit event Transfer(), call _afterTokenTransfer(address(0), to, tokenId, 1)
 _burn(uint256 tokenId)
    internal, owner is defined, call _beforeTokenTransfer(), define owner again, clear approvals, unchecked decrement of owner balance. delete _owners[tokenId], emit transfer event, call _afterTokenTransfer()
 _transfer(address from, address to, uint256 tokenId)
    internal, require owner of tokenId is from. require to is not zero address, call _beforeTokenTransfer(), clear token approvals from previous owner, unchecked decrement previous owner increment new owner. _owners[tokenId] = to. emit transfer event. call _afterTokenTransfer.
 _approve(address to, uint256 tokenId)
    internal, set _tokenApprovals[tokenId] = to. emit approval event. Interestingly, the events being emitted are defined in IERC721.
 _setApprovalForAll(address owner, address operator, bool approved)
    internal, require owner not the same as operator, set _operatorApprovals[owner][operator] = approved. emit approvalForAll event
 _requireMinted(uint256 tokenId)
    internal, Reverts if token has not been minted yet._exists(tokenId)
 _checkOnERC721Received(
        address from,
        address to,
        uint256 tokenId,
        bytes memory data
    )
    private, if to is contract try to compare 'to' contract selector to IERC721Receiver selector to support safeTransferFrom. if not contract return true.
_beforeTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize) 
    internal virtual, Hook that is called before any token transfer. This includes minting and burning. If {ERC721Consecutive} is
     * used, the hook may be called as part of a consecutive (batch) mint, as indicated by `batchSize` greater than 1. To be defined by user.
_afterTokenTransfer(address from, address to, uint256 firstTokenId, uint256 batchSize)
    internal virtual, similar to before token transfer. Hook
__unsafe_increaseBalance(address account, uint256 amount)
    internal, increments balance value for address by amount. Instead of increment by one.