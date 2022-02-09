//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IBondingMinter} from "./interfaces/IBondingMinter.sol";
import {IBondStorage} from "./interfaces/IBondStorage.sol";

contract BondingMinter is IBondingMinter {

    constructor(uint _bondLimit,IBondStorage _bondStorage) {
        bondLimit = _bondLimit;
        bondStorage = _bondStorage;
    }

    /* ========== CONSTANTS ========== */
    uint immutable bondLimit;
    IBondStorage immutable bondStorage;

    /* ========== STATE VARIABLES ========== */

    /* ========== VIEWS ========== */

    function totalSupply() public view override returns(uint) {

    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function mint() public payable override returns(uint) {

    }
    function startBonding() public override {

    }
}