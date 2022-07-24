// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.9;
import "../legacy-contracts/ERC4610.sol";
import "../legacy-contracts/utils/Counters.sol";


contract Muse is ERC4610{
    using Counters for Counters.Counter;
    Counters.Counter private _tokenIdCounter;

    using Strings for uint256;

    // Optional mapping for token URIs
    mapping(uint256 => string) public _tokenURIs;

    mapping(address => mapping(uint => bool)) private _rented;

    mapping(address => string[]) private _myNFts;
    // Mapping owner address to token count
    mapping(uint256 => uint256) private _balances;

    uint public totalSupply;

    event minted(uint id, string image, uint timeCreated);

    event rented(uint id, string image, address owner, address renter);

    event withdrawn(uint id, string image, address owner, uint amount);

    string[] NFTs;

    constructor() ERC4610("Muse", "muse") {}

    function _setTokenURI(uint256 tokenId, string memory _tokenURI) internal virtual {
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function mintNft(string memory uri) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(msg.sender, tokenId);
        _setTokenURI(tokenId, uri);
        totalSupply += 1;
        emit minted(tokenId, uri, block.timestamp);
    }

    function delegate(uint tokenId) public payable{
        address owner = ownerOf(tokenId);
        require(!checkDelegates(msg.sender,tokenId),"asset cannot be delegated more than once");
        require(_msgSender() != owner, "ERC4610: setDelegator to current owner");
        require(!_rented[msg.sender][tokenId],"you cannot rent same asset more than once");
        require(msg.value == 0.1 ether);
        _setDelegator(msg.sender, tokenId);
        _balances[tokenId] += msg.value;
        _rented[msg.sender][tokenId] = true;
        _myNFts[msg.sender].push(_tokenURIs[tokenId]);
        emit rented(tokenId, _tokenURIs[tokenId],owner,msg.sender);
    }

    function withdraw(uint tokenId) public{
        address owner = ownerOf(tokenId);
        require(_exists(tokenId), "ERC721URIStorage: URI set of nonexistent token");
        require(msg.sender == owner, "ERC4610: setDelegator to current owner");
        (bool success,) = msg.sender.call{value:_balances[tokenId]}("");
        require(success,"withdraw failed");
        emit withdrawn(tokenId, _tokenURIs[tokenId], owner, _balances[tokenId]);
    }

    function myNFTs() public view returns(string[] memory){
        return _myNFts[msg.sender];
    }

}