//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IBondStorage } from "../interfaces/IBondStorage.sol";
import { ERC721Burnable } from "@openzeppelin/contracts/token/ERC721/extensions/ERC721Burnable.sol";
import { ERC721 } from "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

contract MockBondStorage is IBondStorage,ERC721Burnable,Ownable {

    constructor(
        string memory _name,
        string memory _symbol
    ) ERC721(_name, _symbol) {}

    /* ========== STATE VARIABLES ========== */
    uint public tokenCounter = 0;

    /* ========== MUTATIVE FUNCTIONS ========== */
    function mint(address to) public override onlyOwner returns(uint tokenId) {
        tokenId = tokenCounter;
        _safeMint(to, tokenCounter);
        // it always increases and we will never mint the same id
        tokenCounter++;
    }

    function transfer(address to, uint tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "BondStorage: You are not the owner");
        _transfer(msg.sender, to, tokenId);
    }

}