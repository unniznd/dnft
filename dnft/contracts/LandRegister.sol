
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/Base64.sol";


contract LandRegister is  ERC721URIStorage{
    using Strings for uint256;
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIds;

    struct OwnedToken{
        string tokenUri;
        uint256 tokenId;
    }

    struct Listing{
        uint256 tokenId;
        uint256 price;
        address payable owner;
        string tokenUri;
    }

    mapping(uint256 => uint256) public tokenIdToLevels;
    mapping(address => OwnedToken[]) private _ownedTokens;
    mapping(uint256 => Listing) public tokenIdToListing;

    constructor() ERC721("LandRegister", "LRK") {}


    event TokenListed(uint256 tokenId, uint256 price, address owner);
    event TokenUnlisted(uint256 tokenId, address owner);

    function getLevels(uint256 tokenId) public view returns (string memory) {
        uint256 levels = tokenIdToLevels[tokenId];
        return levels.toString();
    }

    function generateCharacter(uint256 tokenId) public view returns(string memory){

        bytes memory svg = abi.encodePacked(
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350">',
            '<style>.base { fill: black; font-family: serif; font-size: 14px; }</style>',
            '<rect width="100%" height="100%" fill="white" />',
            '<text x="50%" y="40%" class="base" dominant-baseline="middle" text-anchor="middle">',"Land Register",'</text>',
            '<text x="50%" y="50%" class="base" dominant-baseline="middle" text-anchor="middle">', "LRK ID: ",getLevels(tokenId),'</text>',
            '</svg>'
        );
        return string(
            abi.encodePacked(
                Base64.encode(svg)
            )    
        );
    }
   



    function getTokenURI(uint256 tokenId) public view returns (string memory){
        bytes memory dataURI = abi.encodePacked(
            '{',
                '"name": "Land Register #', tokenId.toString(), '",',
                '"description": "Land Register",',
                '"image": "', generateCharacter(tokenId), '"',
            '}'
        );
        return string(
            abi.encodePacked(
                Base64.encode(dataURI)
            )
        );
    }

    function mint() public {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _safeMint(msg.sender, newItemId);
        tokenIdToLevels[newItemId] = 0;
        string memory _tokenURI = getTokenURI(newItemId);
        _setTokenURI(newItemId, _tokenURI);
        _addTokenToOwner(msg.sender,  newItemId, _tokenURI);
    }
    function train(uint256 tokenId) public {
        require(_exists(tokenId), "Please use an existing token");
        require(ownerOf(tokenId) == msg.sender, "You must own this token to train it");
        uint256 currentLevel = tokenIdToLevels[tokenId];
        tokenIdToLevels[tokenId] = currentLevel + 1;
        _setTokenURI(tokenId, getTokenURI(tokenId));
    }

    function _addTokenToOwner(address owner,  uint256 tokenId, string memory tokenUri) private {
        _ownedTokens[owner].push(OwnedToken(tokenUri, tokenId));
    }

    function _removeTokenFromOwner(address owner, string memory tokenUri) private {
        require(owner != address(0), "Owner cannot be the zero address");
        require(bytes(tokenUri).length > 0, "Token URI cannot be empty");
        
        OwnedToken[] storage tokens = _ownedTokens[owner];
        for (uint256 i = 0; i < tokens.length; i++) {
            if (compareStrings(tokens[i].tokenUri, tokenUri)) {
                tokens[i] = tokens[tokens.length - 1];
                tokens.pop();
                return;
            }
        }
    }

    function compareStrings(string memory a, string memory b) private pure returns (bool) {
        return keccak256(abi.encodePacked(a)) == keccak256(abi.encodePacked(b));
    }


    function transferToken(address from, address to, uint256 tokenId, string memory tokenUri) public {
        transferFrom(from, to, tokenId);
        _removeTokenFromOwner(from, tokenUri);
        _addTokenToOwner(to, tokenId, tokenUri);
    }

    function balanceOf(address owner) public view override returns (uint256) {
        require(owner != address(0), "ERC721: balance query for the zero address");
        return _ownedTokens[owner].length;
    }

    function getTokensOfOwner(address owner) public view returns (OwnedToken[] memory) {
        return _ownedTokens[owner];
    }
    function addToListing(uint256 tokenId, uint256 price) public {
        require(super.ownerOf(tokenId) == msg.sender, "You are not owner of this token");
        require(tokenIdToListing[tokenId].tokenId == 0, "Token is already listed");
        Listing memory listing = Listing(tokenId, price, payable(msg.sender), getTokenURI(tokenId));
        tokenIdToListing[tokenId] = listing;
        emit TokenListed(tokenId, price, msg.sender);
    }

    function removeFromListing(uint256 tokenId) public {
        require(super.ownerOf(tokenId) == msg.sender, "You are not owner of this token");
        require(tokenIdToListing[tokenId].tokenId != 0, "Token is not listed");
        delete tokenIdToListing[tokenId];
        emit TokenUnlisted(tokenId, msg.sender);
    }

    function isListed(uint256 tokenId) public view returns (bool){
        return tokenIdToListing[tokenId].tokenId != 0;
    }

    function buyFromListing(uint256 tokenId, uint256 amount) public payable {
        require(isListed(tokenId), "Token is not listed");
        Listing memory listing = tokenIdToListing[tokenId];
        require(listing.price <= amount, "Price is not correct");
        require(msg.value >= amount, "Amount is not correct");
        listing.owner.transfer(amount);
        transferToken(listing.owner, msg.sender, tokenId, listing.tokenUri);
        removeFromListing(tokenId);
    }

}
