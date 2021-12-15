//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/IERC20.sol";

contract TestCan {
    IERC20 public token;
    
    function canInfo() public view returns (uint,uint,uint,uint,uint,uint,uint,uint,address,uint,uint) {
        return (0,0,0,0,0,0,0,0,address(token),0,0);
    }
    
    constructor (IERC20 _token) {
        token = _token;
    }

    function mintFor(address receiver, uint amount) public {
        require(token.transferFrom(msg.sender, receiver, amount), "TEST_CAN_TRANSFER_ERROR");
    }
}