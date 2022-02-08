//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IBondingMinter} from "../interfaces/IBondingMinter.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract MockBondingMinter is IBondingMinter, Ownable {

    /* ========== CONSTANTS ========== */
    uint immutable bondLimit;
    IERC721 immutable bondStorage;

    /* ========== STATE VARIABLES ========== */

    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */
    function mint() public payable returns(uint) {

    }
}