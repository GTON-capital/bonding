//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IBonding } from "../interfaces/IBonding.sol";
import { IBondStorage } from "../interfaces/IBondStorage.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IStaking } from "@gton/staking/contracts/interfaces/IStaking.sol";
import { UintArray } from "sol-utils/contracts/libraries/UintArray.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


contract MockBonding is IBonding, Ownable, ERC721Holder {

    constructor(
        uint _bondLimit, 
        uint _bondActivePeriod, 
        uint _bondToClaimPeriod, 
        uint _discountNominator,
        IBondStorage _bondStorage, 
        AggregatorV3Interface _tokenAggregator,
        AggregatorV3Interface _gtonAggregator,
        ERC20 _token,
        ERC20 _gton,
        IStaking _sgton
        ) {
        bondLimit = _bondLimit;
        bondActivePeriod = _bondActivePeriod;
        bondToClaimPeriod = _bondToClaimPeriod;
        discountNominator = _discountNominator;
        bondStorage = _bondStorage;
        tokenAggregator = _tokenAggregator;
        gtonAggregator = _gtonAggregator;
        token = _token;
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
            "Bonding: Mint is not available in this period");
        _;
    }

    /* ========== CONSTANTS ========== */

    uint immutable calcDecimals = 1e12;
    uint immutable discountDenominator = 10000;
    uint immutable bondType = "7d";
    /* ========== STATE VARIABLES ========== */

    uint lastBondActivation;
    // amount in ms. Shows amount of time when this contract can issue the bonds
    uint bondActivePeriod;
    // Amount in ms. Bond will be available to claim after this period of time
    uint bondToClaimPeriod;
    uint bondLimit;
    uint bondCounter;
    uint discountNominator;
    uint[] activeBonds;

    ERC20 token;
    ERC20 gton;
    IStaking sgton;
    IBondStorage bondStorage;
    AggregatorV3Interface tokenAggregator;
    AggregatorV3Interface gtonAggregator;

    mapping(uint => address) userBond;

    /* ========== VIEWS ========== */

    function isActiveBond(uint id) public view returns(bool) {
        return UintArray.indexOf(activeBonds, id) >= 0;
    }

    /**
     * View function returns timestamp when bond period vill be over
     */
    function bondExpiration() public view returns(uint) {
        return lastBondActivation + bondActivePeriod;
    }

    /**
     * Function that returns data from aggregator
     */
    function tokenPriceAndDecimals(AggregatorV3Interface _token) internal view returns (int256 price, uint decimals) {
        decimals = _token.decimals();
        (, price,,,) = _token.latestRoundData();
    }

    /**
     * Function calculates the amount of gton out for current price without discount
     */
    function bondAmountOut(uint amountIn) public view returns (uint amountOut) {
        (int256 gtonPrice, uint gtonDecimals) = tokenPriceAndDecimals(gtonAggregator);
        (int256 tokenPrice, uint tokenDecimals) = tokenPriceAndDecimals(tokenAggregator);
        uint tokenInUSD = amountIn * uint(tokenPrice)  / tokenDecimals;
        amountOut = tokenInUSD / uint(gtonPrice) / gtonDecimals;
    }

    /**
     * Function calculates the  amount of token that represents
     */
    function amountWithoutDiscount(uint amount) public view returns (uint) {
        // to keep contract representation correctly
        uint givenPercent = discountDenominator - discountNominator;
        /**
            For example:
            discount - 25%
            givenPercent = 100-25 = 75
            amountWithoutDiscount = amount / 75 * 100
         */
        return amount * discountDenominator / givenPercent;
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
        require(!isBondingActive(), "Bonding: Bonding is already active");
        lastBondActivation = block.timestamp;
    }

    function _mint(uint amount, address user, string memory _bondType) internal returns(uint) {
        require(bondLimit > bondCounter, "Bonding: Exceeded amount of bonds");
        require(token.transferFrom(msg.sender, address(this), amount), "Bonding: Insufficient approve");
        uint amountWithoutDis = amountWithoutDiscount(amount);
        uint sgtonAmount = bondAmountOut(amountWithoutDis);

        uint id = bondStorage.mint(msg.sender);
        activeBonds.push(id);

        bondCounter++;
        emit Mint(id, msg.sender);
        emit MintData(token, amountWithoutDis, releaseTimestamp, _bondType);
    }

    /**
     * Function issues bond to user by minting the NFT token for them.
     */
    function mint(uint amount) public payable mintEnabled returns(uint id) {
        id = _mint(amount, msg.sender, bondType);
    }

    /**
     * Function receives the bond from user and updates users balance with sgton
     *
     */
    function claim(uint tokenId) public override {

    }

     /* ========== RESTRICTED ========== */

    function mintFor(uint amount, address user, string memory _bondType) public payable onlyOwner returns(uint id) {
        id = _mint(amount, user, _bondType);
    }

    // @TODO: add state changers 

}