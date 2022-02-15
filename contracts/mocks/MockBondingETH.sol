//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IBonding } from "../interfaces/IBonding.sol";
import { IBondStorage } from "../interfaces/IBondStorage.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IStaking } from "@gton/staking/contracts/interfaces/IStaking.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


contract MockBonding is IBonding, Ownable, ERC721Holder {

    constructor(
        uint _bondLimit, 
        uint _bondPeriod, 
        IBondStorage _bondStorage, 
        AggregatorV3Interface _aggregator,
        ERC20 _token,
        ERC20 _gton,
        IStaking _sgton
        ) {
        bondLimit = _bondLimit;
        bondPeriod = _bondPeriod;
        bondStorage = _bondStorage;
        aggregator = _aggregator;
        tokenAddress = _token;
        gton = _gton;
        sgton = _sgton;
    }

    /* ========== MODIFIERS  ========== */

    /**
     * Mofidier checks if bonding period is open and provides access to the function
     * It is used for mint function.
     */
    modifier mintEnabled() {
        require(isBondingActive(), 
            "BondingMinter: Mint is not available in this period");
        _;
    }

    /* ========== CONSTANTS ========== */
    
    uint immutable calcDecimals = 1e12;
    uint immutable discountDenominator = 10000;

    /* ========== STATE VARIABLES ========== */

    uint lastBondActivation;
    uint bondPeriod;
    uint bondLimit;
    uint bondCounter;

    ERC20 tokenAddress;
    ERC20 gton;
    IStaking sgton;
    IBondStorage bondStorage;
    AggregatorV3Interface aggregator;

    mapping(uint => address) userBond;

    /* ========== VIEWS ========== */

    /**
     * View function returns timestamp when bond period vill be over
     */
    function bondExpiration() public view returns(uint) {
        return lastBondActivation + bondPeriod;
    }

    /**
     * Function that returns data from aggregator
     */
    function tokenPriceAndDecimals(AggregatorV3Interface token) internal view returns (int256 price, uint decimals) {
        decimals = token.decimals();
        (, price,,,) = token.latestRoundData();
    }

    /**
     * Function checks if bond period is open by checking 
     * that last block timestamp is between bondEpiration timestamp and lastBondActivation timestamp.
     */
    function isBondingActive() public view returns(bool) {
        return block.timestamp >= lastBondActivation && block.timestamp <= bondExpiration();
    }

    /**
     * Function returns total amount of bonds issued by this contract
     */
    function totalSupply() public view override returns(uint) {
        return bondCounter;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * Function starts issue bonding period
     */
    function startBonding() public override onlyOwner {
        require(!isBondingActive(), "BondingMinter: Bonding is already active");
        lastBondActivation = block.timestamp;
    }

    /**
     * Function issues bond to user by minting the NFT token for them.
     * 
     */
    function mint() public payable override mintEnabled returns(uint) {
        require(bondLimit > bondCounter, "BondMinter: Exceeded amount of bonds");
        uint id = bondStorage.mint(msg.sender);
        bondCounter++;
        return id;
    }

    /**
     * Function receives the bond from user and updates users balance with sgton
     *
     */
    function claim(uint tokenId) public override {

    }

}