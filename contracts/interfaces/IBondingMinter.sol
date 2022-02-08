//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBondingMinter {
    event StartBonding(uint startTimestamp, uint endTimestamp);
    event Mint(address indexed tokenId, address indexed user);
    event MintData(address indexed asset, uint allocation, uint release, string bondType);

    function startBonding() external;
    function totalSupply() external view returns (uint);
    function mint() external payable returns (uint);
}