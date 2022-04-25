//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { ABonding } from "./ABonding.sol";
import { IBondStorage } from "./interfaces/IBondStorage.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IStaking } from "./interfaces/IStaking.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


contract Bonding is ABonding {

    constructor(
        uint bondLimit_,
        uint bondActivePeriod_,
        uint bondToClaimPeriod_,
        uint discountNominator_,
        IBondStorage bondStorage_,
        AggregatorV3Interface tokenAggregator_,
        AggregatorV3Interface gtonAggregator_,
        ERC20 token_,
        ERC20 gton_,
        IStaking sgton_,
        string memory bondType_
        ) ABonding(
            bondLimit_,
            bondActivePeriod_,
            bondToClaimPeriod_,
            discountNominator_,
            bondStorage_,
            tokenAggregator_,
            gtonAggregator_,
            token_,
            gton_,
            sgton_,
            bondType_
        ){}

     /* ========== RESTRICTED ========== */

    /**
     * Function issues bond to user by minting the NFT token for them.
     */
    function mint(uint amount) external mintEnabled returns(uint id) {
        require(token.transferFrom(msg.sender, address(this), amount));
        uint releaseTimestamp = block.timestamp + bondToClaimPeriod;
        id = _mint(amount, msg.sender, releaseTimestamp);
    }
}
