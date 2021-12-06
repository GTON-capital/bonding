//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IWETH.sol";
import './libraries/UniswapV2Library.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';

contract Bounding {
    IWETH public eth;
    IERC20 public gton;
    address public treasury;

    address public owner;
    bool public revertFlag;
    uint contractRequiredGtonBalance;
    Discounts[] public discounts;
    mapping (address => UserUnlock[]) public userUnlock;
    mapping (address => bool) allowedTokens;

    struct UserUnlock {
        uint rewardDebt;
        uint amount;
        uint startBlock;
        uint delta;
    }

    struct Discounts {
        uint delta;
        uint discountMul;
        uint discountDiv;
        uint minimalAmount;
    }


    modifier onlyOwner() {
        require(msg.sender == owner,"not owner");
        _;
    }     

    constructor (
        IWETH _eth,
        IERC20 _gton,
        address _treasury,
        address _owner
    ) {
        eth = _eth;
        gton = _gton;
        treasury = _treasury;
        owner = _owner;
    }

    function createBound (uint boundId, uint tokenAmount) internal {
        Discounts memory disc = discounts[boundId];

        userUnlock[msg.sender]
    }

    function setThePrice(
        uint[] calldata quotesUpper, 
        uint[] calldata quotesLower, 
        address[] calldata pools
    ) onlyOwner public {
        for (uint i = 0; i < pools.length; i++) {
            
        }
    }
}