//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";

abstract contract AdminAccess is Ownable {

    mapping(address => bool) admins;

    modifier onlyAdminOrOwner() {
        require(isAdmin(msg.sender) || owner() == msg.sender);
        _;
    }

    function isAdmin(address user) public view returns(bool) {
        return admins[user];
    }

    function setAdmin(address user) public onlyOwner {
        admins[user] = true;
    }

    function unsetAdmin(address user) public onlyOwner {
        admins[user] = false;
    }

}