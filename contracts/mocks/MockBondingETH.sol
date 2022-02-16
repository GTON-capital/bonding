//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IBonding } from "../interfaces/IBonding.sol";
import { IBondStorage } from "../interfaces/IBondStorage.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { Staking } from "@gton/staking/contracts/Staking.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


contract MockBondingETH is IBonding, Ownable, ERC721Holder {

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
        Staking _sgton,
        string memory _bondType
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
        bondType = _bondType;
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

    uint immutable discountDenominator = 10000;

    /* ========== STATE VARIABLES ========== */

    string bondType;
    uint lastBondActivation;
    // amount in ms. Shows amount of time when this contract can issue the bonds
    uint bondActivePeriod;
    // Amount in ms. Bond will be available to claim after this period of time
    uint bondToClaimPeriod;
    uint bondLimit;
    uint bondCounter;
    uint discountNominator;
    mapping (uint => BondData) activeBonds;

    struct BondData {
        bool isActive;
        uint issueTimestamp;
        uint releaseTimestamp;
        string bondType;
        uint releaseAmount;
    }

    ERC20 token;
    ERC20 gton;
    Staking sgton;
    IBondStorage bondStorage;
    AggregatorV3Interface tokenAggregator;
    AggregatorV3Interface gtonAggregator;

    /* ========== VIEWS ========== */

    function isActiveBond(uint id) public view returns(bool) {
        return activeBonds[id].isActive;
    }

    /**
     * Function calculates amount of token to be earned with the `amount` by the bond duration time
     */
    function getStakingReward(uint amount) public view returns(uint) {
        uint stakingN = sgton.aprBasisPoints();
        uint stakingD = sgton.aprDenominator();
        uint calcDecimals = sgton.calcDecimals();
        uint secondsInYear = sgton.secondsInYear();
        uint yearEarn = amount * calcDecimals * stakingN / stakingD;
        return yearEarn * bondToClaimPeriod / secondsInYear / calcDecimals; 
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

    function _mint(uint amount, address user, string memory _bondType) internal returns(uint id) {
        require(bondLimit > bondCounter, "Bonding: Exceeded amount of bonds");
        require(msg.value >= amount, "Bonding: Insufficient amount of ETH");
        uint amountWithoutDis = amountWithoutDiscount(amount);
        uint sgtonAmount = bondAmountOut(amountWithoutDis);
        uint reward = getStakingReward(sgtonAmount);
        uint bondReward = sgtonAmount + reward;
        uint releaseTimestamp = block.timestamp + bondToClaimPeriod;
        id = bondStorage.mint(user);

        activeBonds[id] = BondData(true, block.timestamp, releaseTimestamp, _bondType, bondReward);

        bondCounter++;
        emit Mint(id, user);
        emit MintData(address(token), bondReward, releaseTimestamp, _bondType);
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