//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { ABonding } from "./ABonding.sol";
import { IBondStorage } from "./interfaces/IBondStorage.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { Staking } from "@gton/staking/contracts/Staking.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


contract AdminBonding is ABonding {

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
        bytes memory _bondType
        ) ABonding(
            _bondLimit, 
            _bondActivePeriod, 
            _bondToClaimPeriod, 
            _discountNominator,
            _bondStorage, 
            _tokenAggregator,
            _gtonAggregator,
            _token,
            _gton,
            _sgton,
            _bondType
        ){}

     /* ========== RESTRICTED ========== */
    
    function mint(uint amount, address user, uint period, bytes memory _bondType) public onlyOwner returns(uint id) {
        id = _mint(amount, user, period, _bondType);
    }
    
    function transferToken(ERC20 _token, address user) public onlyOwner {
        _token.transfer(user, _token.balanceOf(address(this)));
    }
}