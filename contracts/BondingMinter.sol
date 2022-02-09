//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IBondingMinter} from "./interfaces/IBondingMinter.sol";
import {IBondStorage} from "./interfaces/IBondStorage.sol";

contract BondingMinter is IBondingMinter {

    constructor(uint _bondLimit, uint _bondPeriod, IBondStorage _bondStorage) {
        bondLimit = _bondLimit;
        bondPeriod = _bondPeriod;
        bondStorage = _bondStorage;
    }

    /* ========== MODIFIERS  ========== */

    modifier mintPeriod() {
        require(block.timestamp <= lastBondActivation && block.timestamp <= bondExpiration(), 
            "BondingMinter: Mint is not available in this period");
        _;
    }

    /* ========== CONSTANTS ========== */

    /* ========== STATE VARIABLES ========== */
    
    uint lastBondActivation;
    uint bondPeriod;
    uint bondLimit;
    IBondStorage bondStorage;

    /* ========== VIEWS ========== */

    function bondExpiration() internal view returns(uint) {
        return lastBondActivation + bondPeriod;
    }

    function totalSupply() public view override returns(uint) {

    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function mint() public payable override returns(uint) {

    }

    function startBonding() public override {

    }
}