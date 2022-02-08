//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IBondingMinter} from "./interfaces/IBondingMinter.sol";
import {IERC721} from "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract BondingMinter is IBondingMinter {

    uint immutable bondLimit;
    IERC721 immutable bondStorage;

    function mint() public payable returns(uint) {

    }
}