//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IBondingClaimer is IERC721Receiver {
    /**
     * @dev Emitted when `user` claims `tokenId` bond.
     */
    event Claim(address indexed user, uint tokenId);

    /**
     * @dev Releases sGTON token for user by it's `tokenId`.

     * Emits {Claim} event.
     */
    function claim(uint tokenId) external;
}