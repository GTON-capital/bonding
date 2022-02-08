//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IBondingClaimer} from "../interfaces/IBondingClaimer.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract MockBondingClaimer is IBondingClaimer {
    
    IERC721 bondStorage;

    function claim(uint tokenId) public override {

    }
}