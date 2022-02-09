//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import {IBondStorage} from "../interfaces/IBondStorage.sol";
import {ERC721} from "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract BondStorage is IBondStorage,ERC721 {

}