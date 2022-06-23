//SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import { IBasicBonding } from "../interfaces/IBasicBonding.sol";
import { IBondStorage } from "../interfaces/IBondStorage.sol";
import { IWhitelist } from "../interfaces/IWhitelist.sol";
import { InitializableOwnable } from "../interfaces/InitializableOwnable.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IOracleUsd } from "../interfaces/IOracleUsd.sol";
import { IStaking } from "../interfaces/IStaking.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";
import { ReentrancyGuard } from "@openzeppelin/contracts/security/ReentrancyGuard.sol";

abstract contract ATwapBonding is IBasicBonding, InitializableOwnable, ERC721Holder, ReentrancyGuard {

    /* ========== CONSTANTS ========== */

    uint constant public discountDenominator = 10000;
    uint public constant Q112 = 2 ** 112;

    /* ========== STATE VARIABLES ========== */

    bytes bondTypeBytes;
    uint public lastBondActivation;
    // amount in ms. Shows amount of time when this contract can issue the bonds
    uint public bondActivePeriod;
    // Amount in ms. Bond will be available to claim after this period of time
    uint public bondToClaimPeriod;
    uint public bondLimit;
    uint public bondCounter;
    uint public discountNominator;
    bool public isWhitelistActive;
    mapping (uint => BondData) public activeBonds;
    mapping(address => uint[]) public userBonds;
    IWhitelist public whitelist;

    struct BondData {
        bool isActive;
        uint issueTimestamp;
        uint releaseTimestamp;
        uint releaseAmount;
    }

    ERC20 immutable public token;
    ERC20 immutable  public gton;
    IStaking immutable public sgton;
    IBondStorage immutable public bondStorage;
    AggregatorV3Interface public tokenOracle;
    IOracleUsd public gtonOracle;

    /* ========== Constructor ========== */

    constructor(
        uint bondLimit_,
        uint bondActivePeriod_,
        uint bondToClaimPeriod_, 
        uint discountNominator_,
        IBondStorage bondStorage_,
        AggregatorV3Interface tokenOracle_,
        IOracleUsd gtonOracle_,
        ERC20 token_,
        ERC20 gton_,
        IStaking sgton_,
        string memory bondType_
        ) {
        initOwner(msg.sender);
        bondLimit = bondLimit_;
        bondActivePeriod = bondActivePeriod_;
        bondToClaimPeriod = bondToClaimPeriod_;
        discountNominator = discountNominator_;
        bondStorage = bondStorage_;
        tokenOracle = tokenOracle_;
        gtonOracle = gtonOracle_;
        token = token_;
        gton = gton_;
        sgton = sgton_;
        bondTypeBytes = bytes(bondType_);
    }

    /* ========== VIEWS ========== */

    function isActiveBond(uint id) public view returns(bool) {
        return activeBonds[id].isActive;
    }

    function bondType() public view returns(string memory) {
        return string(bondTypeBytes);
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
    function bondingWindowEndTimestamp() public view returns(uint) {
        return lastBondActivation + bondActivePeriod;
    }

    /**
     * Function that returns data from aggregator
     */
    function tokenPriceAndDecimals(AggregatorV3Interface token_) internal view returns (int256 price, uint decimals) {
        decimals = token_.decimals();
        (, price,,,) = token_.latestRoundData();
    }

    /**
     * Function calculates the amount of gton out for current price without discount
     */
    function bondAmountOut(uint amountIn) public view returns (uint amountOut) {
        (int256 tokenPrice, uint tokenDecimals) = tokenPriceAndDecimals(tokenOracle);

        // Getting Q112-encoded price of 1 GTON
        uint gtonPriceQ112 = gtonOracle.assetToUsd(address(gton), 1e18);
        uint gtonPrice = 100 * Q112 / gtonPriceQ112;
        amountOut = amountIn * uint(tokenPrice) / tokenDecimals / gtonPrice;
    }

    /**
     * Function calculates the amount of token that represents
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
     * that last block timestamp is between bondExpiration timestamp and lastBondActivation timestamp.
     */
    function isBondingActive() public view returns(bool) {
        return block.timestamp >= lastBondActivation && block.timestamp <= bondingWindowEndTimestamp();
    }

    /**
     * Function returns total amount of bonds issued by this contract
     */
    function totalSupply() external view override returns(uint) {
        return bondCounter;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    // Amount: token count without decimals
    function _mint(uint amount, address user, uint releaseTimestamp) internal nonReentrant returns(uint id) {
        require(bondLimit > bondCounter, "Bonding: Exceeded amount of bonds");
        uint amountWithoutDis = amountWithoutDiscount(amount);
        uint sgtonAmount = bondAmountOut(amountWithoutDis);
        bondCounter++;
        if (isWhitelistActive) {
            uint allowedAllocation = whitelist.allowedAllocation(user);
            require(sgtonAmount <= allowedAllocation, "Bonding: You are not allowed for this allocation");
            whitelist.updateAllocation(user, allowedAllocation - sgtonAmount);
        }
        uint reward = getStakingReward(sgtonAmount);
        uint bondReward = sgtonAmount + reward;

        id = bondStorage.mint(user, releaseTimestamp, bondReward);
        activeBonds[id] = BondData(true, block.timestamp, releaseTimestamp, bondReward);
        userBonds[user].push(id);

        emit Mint(id, user);
        emit MintData(address(token), bondReward, releaseTimestamp, bondType());
    }

    /**
     * Function receives the bond from user and updates users balance with sgton
     */
    function claim(uint tokenId) external override {
        // No need to add checks if bond was issued on this contract because the id of bond is unique
        require(isActiveBond(tokenId), "Bonding: Cannot claim inactive bond");
        BondData storage bond = activeBonds[tokenId];
        bond.isActive = false;

        require(bond.releaseTimestamp <= block.timestamp, "Bonding: Bond is locked to claim now");
        bondStorage.safeTransferFrom(msg.sender, address(this), tokenId);

        if (!(gton.approve(address(sgton), bond.releaseAmount))) { revert(); }
        sgton.stake(bond.releaseAmount, msg.sender);
        emit Claim(msg.sender, tokenId);
    }

     /* ========== RESTRICTED ========== */
    
    /**
     * Function starts issue bonding period
     */
    function startBonding() external override onlyOwner {
        require(!isBondingActive(), "Bonding: Bonding is already active");
        lastBondActivation = block.timestamp;
        emit BondingStarted(lastBondActivation, bondActivePeriod);
    }

    function setGtonOracle(IOracleUsd agg) external onlyOwner {
        address oldValue = address(gtonOracle);
        gtonOracle = agg;
        emit SetGtonOracle(oldValue, address(agg));
    }

    function setTokenOracle(AggregatorV3Interface agg) external onlyOwner {
        address oldValue = address(tokenOracle);
        tokenOracle = agg;
        emit SetTokenOracle(oldValue, address(agg));
    }

    function setDiscountNominator(uint discountN_) external onlyOwner {
        uint oldValue = discountNominator;
        discountNominator = discountN_;
        emit SetDiscountNominator(oldValue, discountN_);
    }

    function setBondActivePeriod(uint bondActivePeriod_) external onlyOwner {
        uint oldValue = bondActivePeriod;
        bondActivePeriod = bondActivePeriod_;
        emit SetBondActivePeriod(oldValue, bondActivePeriod_);
    }

    function setBondToClaimPeriod(uint bondToClaimPeriod_) external onlyOwner {
        uint oldValue = bondToClaimPeriod;
        bondToClaimPeriod = bondToClaimPeriod_;
        emit SetBondToClaimPeriod(oldValue, bondToClaimPeriod_);
    }

    function setBondLimit(uint bondLimit_) external onlyOwner {
        uint oldValue = bondLimit;
        bondLimit = bondLimit_;
        emit SetBondLimit(oldValue, bondLimit_);
    }

    function setWhitelist(IWhitelist whitelist_) external onlyOwner {
        address oldValue = address(whitelist);
        whitelist = whitelist_;
        emit SetWhitelist(oldValue, address(whitelist_));
    }

    function toggleWhitelist() external onlyOwner {
        isWhitelistActive = !isWhitelistActive;
        emit ToggleWhitelist(isWhitelistActive);
    }
    
    function transferToken(ERC20 token_, address user) external onlyOwner {
        require(token_.transfer(user, token_.balanceOf(address(this))));
    }

    /* ========== MODIFIERS  ========== */

    /**
     * Mofidier checks if bonding period is open and provides access to the function
     * It is used for mint function.
     */

    modifier mintEnabled() {
        require(isWhitelistActive || isBondingActive(), 
            "Bonding: Mint is not available in this period");
        _;
    }
}
