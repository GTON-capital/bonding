//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract MockAggregator is AggregatorV3Interface {

    constructor(
        uint8 dec,
        int256 price
    ) {
        _decimals = dec;
        _price = price;
    }

    uint8 _decimals;
    int256 _price;

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function description() public override view returns (string memory) {
        return "";
    }

    function version() public override view returns (uint256) {

    }

    function getRoundData(uint80 _roundId)
        public override
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (0, 0, 0, 0, 0);
    }

    function latestRoundData()
        public 
        override
        view
        returns (
        uint80 roundId,
        int256 answer,
        uint256 startedAt,
        uint256 updatedAt,
        uint80 answeredInRound
    ) {
        return (0, _price, 0, 0, 0);
    }

    function updatePriceAndDecimals(
        int256 price,
        uint8 dec
    ) public {
        _decimals = dec;
        _price = price;
    }
}
