//SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import { ATwapBonding } from "./ATwapBonding.sol";
import { IBondStorage } from "../interfaces/IBondStorage.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IOracleUsd } from "../interfaces/IOracleUsd.sol";
import { IStaking } from "../interfaces/IStaking.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract GTONTwapBondingETH is ATwapBonding {

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
        ) ATwapBonding(
            bondLimit_,
            bondActivePeriod_,
            bondToClaimPeriod_,
            discountNominator_,
            bondStorage_,
            tokenOracle_,
            gtonOracle_,
            token_,
            gton_,
            sgton_,
            bondType_
        ){}

     /* ========== RESTRICTED ========== */

    /**
     * Function issues bond to user by minting the NFT token for them.
     * Amount: token count without decimals
     */
    function mint(uint amount) external payable mintEnabled returns(uint id) {
        require(msg.value >= amount, "Bonding: Insufficient amount of ETH");
        uint releaseTimestamp = block.timestamp + bondToClaimPeriod;
        id = _mint(amount, msg.sender, releaseTimestamp);
    }

    function transferNative(address payable to) external onlyOwner {
        to.transfer(address(this).balance);
    }
}
