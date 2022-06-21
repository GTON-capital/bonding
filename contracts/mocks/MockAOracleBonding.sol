//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { AOracleBonding } from "../oracle/AOracleBonding.sol";
import { IBondStorage } from "../interfaces/IBondStorage.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IStaking } from "./../interfaces/IStaking.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract MockAOracleBonding is AOracleBonding {

    constructor(
        uint _bondLimit, 
        uint _bondActivePeriod, 
        uint _bondToClaimPeriod, 
        uint _discountNominator,
        IBondStorage _bondStorage, 
        AggregatorV3Interface _tokenOracle,
        AggregatorV3Interface _gtonOracle,
        ERC20 _token,
        ERC20 _gton,
        IStaking _sgton,
        string memory _bondType
        ) AOracleBonding(
            _bondLimit, 
            _bondActivePeriod, 
            _bondToClaimPeriod, 
            _discountNominator,
            _bondStorage, 
            _tokenOracle,
            _gtonOracle,
            _token,
            _gton,
            _sgton,
            _bondType
        ){}

    /**
     * Function issues bond to user by minting the NFT token for them.
     */
    function mint(uint amount) public returns(uint id) {
        uint releaseTimestamp = block.timestamp + bondToClaimPeriod;
        id = _mint(amount, msg.sender, releaseTimestamp);
    }

}
