//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IBondStorage } from "./interfaces/IBondStorage.sol";
import { AdminAccess } from "./access/AdminAccess.sol";
import { ERC721Burnable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BondStorage is IBondStorage,ERC721Burnable,AdminAccess {

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    /* ========== STATE VARIABLES ========== */
    uint public tokenCounter = 0;
    mapping(address => uint[]) public userIds;
    mapping(uint => address) public issuedBy;

    function userIdsLength(address user) public view returns(uint) {
        return userIds[user].length;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function mint(address to) public override onlyAdminOrOwner returns(uint tokenId) {
        tokenId = tokenCounter;
        _safeMint(to, tokenCounter);
        userIds[to].push(tokenId);
        issuedBy[tokenId] = msg.sender;
        // it always increases and we will never mint the same id
        tokenCounter++;
    }

    function transfer(address to, uint tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "BondStorage: You are not the owner");
        _transfer(msg.sender, to, tokenId);
    }

}