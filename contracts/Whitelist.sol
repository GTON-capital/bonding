//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IWhitelist } from "./interfaces/IWhitelist.sol";
import { AdminAccess } from "./access/AdminAccess.sol";

contract Whitelist is IWhitelist, AdminAccess {

    mapping(address => uint) whitelist;

    function isWhitelisted(address user) public view returns(bool) {
        return whitelist[user] > 0;
    }
    
    function allowedAllocation(address user) public view returns(uint) {
        return whitelist[user];
    }

    function updateAllocation(address user, uint allocation) public onlyAdminOrOwner {
        whitelist[user] = allocation;
    }
}
