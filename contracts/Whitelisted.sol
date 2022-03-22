//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IWhitelist } from "./interfaces/IWhitelist.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract Whitelisted {

    IWhitelist public whitelist;

    modifier isWhitelisted(uint amount) {
        uint allowed = whitelist.allowedAllocation(msg.sender);
        require(amount <= allowed, "Whitelisted: you are not allowed to work with this amount");
        _;
    }

}