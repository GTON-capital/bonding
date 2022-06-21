//SPDX-License-Identifier: MIT
pragma solidity >=0.8.15;

import { InitializableOwnable } from "../interfaces/InitializableOwnable.sol";
import { IWhitelist } from "../interfaces/IWhitelist.sol";

contract GTONSimpleWhitelist is InitializableOwnable, IWhitelist {

    mapping(address => uint) whitelist;

    constructor() {
        initOwner(msg.sender);
    }

    function isWhitelisted(address user) public view returns(bool) {
        return whitelist[user] > 0;
    }
    
    function allowedAllocation(address user) public view returns(uint) {
        return whitelist[user];
    }

    function updateAllocation(address user, uint allocation) public onlyOwner {
        whitelist[user] = allocation;
    }
}
