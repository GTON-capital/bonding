//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract TestAggregator {
    uint public decimals;
    int public price;

    constructor (
        uint _decimals,
        int _price
    ) {
        decimals = _decimals;
        price = _price;
    }
    
    function setPrice(int256 p) public {
        price = p;
    }

    function latestRoundData() public view returns (
      uint80 roundId,
      int256 answer,
      uint256 startedAt,
      uint256 updatedAt,
      uint80 answeredInRound
    ) {
        return (1, price, 1, 2, 1);
    }
}