//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IBondingClaimer } from "./interfaces/IBondingClaimer.sol";
import { IBondStorage } from "./interfaces/IBondStorage.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract BondingClaimer is IBondingClaimer, ERC721Holder {

    constructor(IBondStorage _bondStorage) {
        bondStorage = _bondStorage;
    }

    /* ========== CONSTANTS ========== */

    /* ========== STATE VARIABLES ========== */
    IBondStorage bondStorage;
    /* ========== VIEWS ========== */

    /* ========== MUTATIVE FUNCTIONS ========== */
    function claim(uint tokenId) public override {

    }
}