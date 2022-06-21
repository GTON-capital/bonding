//SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import { IBondStorage } from "./interfaces/IBondStorage.sol";
import { AdminAccess } from "./access/AdminAccess.sol";
import { ERC721Burnable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Mock storage for testing purposes

contract BondStorage is IBondStorage, ERC721Burnable, AdminAccess {

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    /* ========== STATE VARIABLES ========== */
    uint public tokenCounter = 0;
    mapping(address => uint[]) public userIds;
    mapping(uint => address) public issuedBy;
    mapping(uint => string) public releaseDates;
    mapping(uint => uint) public rewards;
    string public bondTokenSymbol;

    function userIdsLength(address user) external view returns(uint) {
        return userIds[user].length;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function mint(address to, uint releaseTimestamp, uint reward) external override onlyAdminOrOwner returns(uint tokenId) {
        tokenId = tokenCounter;
        // it always increases and we will never mint the same id
        tokenCounter++;
        _safeMint(to, tokenCounter - 1);
        userIds[to].push(tokenId);
        issuedBy[tokenId] = msg.sender;
        releaseDates[tokenId] = "Test date string";
        rewards[tokenId] = reward;
    }

    function transfer(address to, uint tokenId) external {
        require(ownerOf(tokenId) == msg.sender, "BondStorage: You are not the owner");
        _transfer(msg.sender, to, tokenId);
    }
}
