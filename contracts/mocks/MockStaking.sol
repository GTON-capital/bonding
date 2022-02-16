//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Staking } from "@gton/staking/contracts/Staking.sol";
import { IERC20 } from "@gton/staking/contracts/interfaces/IERC20.sol";

contract MockStaking is Staking {

    constructor(
        IERC20 _token,
        string memory _name,
        string memory _symbol,
        uint _aprBasisPoints,
        uint _harvestInterval
    ) Staking(
         _token,
        _name,
        _symbol,
        _aprBasisPoints,
        _harvestInterval
    ) {}
}
