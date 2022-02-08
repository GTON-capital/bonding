//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBondingClaimer {
    event Burn(address indexed tokenId, address indexed user);
    event MintData(address indexed asset, uint allocation, uint release, string bondType);

    function claim(uint tokenId) external;
}