//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IBondingMinter } from "./interfaces/IBondingMinter.sol";
import { IBondStorage } from "./interfaces/IBondStorage.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";


contract BondingMinter is IBondingMinter, Ownable {

    constructor(
        uint _bondLimit, 
        uint _bondPeriod, 
        IBondStorage _bondStorage, 
        AggregatorV3Interface _aggregator
        ) {
        bondLimit = _bondLimit;
        bondPeriod = _bondPeriod;
        bondStorage = _bondStorage;
        aggregator = _aggregator;
    }

    // Should we add fallback function here?

    /* ========== MODIFIERS  ========== */

    modifier mintEnabled() {
        require(isBondingActive(), 
            "BondingMinter: Mint is not available in this period");
        _;
    }

    /* ========== CONSTANTS ========== */

    /* ========== STATE VARIABLES ========== */

    uint lastBondActivation;
    uint bondPeriod;
    uint bondLimit;
    IBondStorage bondStorage;
    AggregatorV3Interface aggregator;

    /* ========== VIEWS ========== */

    function bondExpiration() internal view returns(uint) {
        return lastBondActivation + bondPeriod;
    }

    function isBondingActive() public view returns(bool) {
        return block.timestamp <= lastBondActivation && block.timestamp <= bondExpiration();
    }

    function totalSupply() public view override returns(uint) {

    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function startBonding() public override onlyOwner {
        require(!isBondingActive(), "BondingMinter: Bonding is already active");
        lastBondActivation = block.timestamp;
    }

    function mint() public payable override mintEnabled returns(uint) {
        uint id = bondStorage.mint(msg.sender);
        return id;
    }

}