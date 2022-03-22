//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IWhitelist {
    function isWhitelisted(address user) external returns(bool);
    function allowedAllocation(address user) external returns(uint);
    function updateAllocation(address user, uint allocation) external;
}