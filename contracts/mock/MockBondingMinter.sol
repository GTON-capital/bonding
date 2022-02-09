//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {IBondingMinter} from "../interfaces/IBondingMinter.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {IBondStorage} from "../interfaces/IBondStorage.sol";

contract MockBondingMinter is IBondingMinter, Ownable {

    constructor(uint _bondLimit, IBondStorage _bondStorage) {
        bondLimit = _bondLimit;
        bondStorage = _bondStorage;
    }

    /* ========== CONSTANTS ========== */

    /* ========== STATE VARIABLES ========== */

    uint bondLimit;
    IBondStorage bondStorage;
    
    /* ========== VIEWS ========== */

    function totalSupply() public view override returns(uint) {

    }

    /* ========== MUTATIVE FUNCTIONS ========== */
    function mint() public payable override returns(uint) {

    }
    
    function startBonding() public override {

    }
}