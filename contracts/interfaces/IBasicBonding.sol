//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IERC721Receiver } from "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

interface IBasicBonding is IERC721Receiver {

    /**
     * @dev Emitted when the bond period opens. 
     * Emits bond period bordes with `startTimestamp` and `endTimestamp`.
     */
    event StartBonding(uint startTimestamp, uint endTimestamp);

    /**
     * @dev Emitted when the bond is minted for `user` with `tokenId` id. 
     */
    event Mint(uint indexed tokenId, address indexed user);

    /**
     * @dev Emitted when the bond is minted. 
     * Emits bond MetaData:
     * `asset` - token to be released in the end of the bond
     * `allocation` - amount to be released
     * `releaseDate` - timestamp, when the bond will be available to claim
     * `bondType` - string representation of bondType
     */
    event MintData(address indexed asset, uint allocation, uint releaseDate, string bondType);

    /**
     * @dev Emitted when `user` claims `tokenId` bond.
     */
    event Claim(address indexed user, uint tokenId);

    /**
     * @dev A set of events for updating contract parameters
     */
    event SetGtonAggregator(address oldValue, address newValue);
    event SetTokenAggregator(address oldValue, address newValue);
    event SetDiscountNominator(uint oldValue, uint newValue);
    event SetBondActivePeriod(uint oldValue, uint newValue);
    event SetBondToClaimPeriod(uint oldValue, uint newValue);
    event SetBondLimit(uint oldValue, uint newValue);
    event SetWhitelist(address oldValue, address newValue);
    event ToggleWhitelist(bool value);
    event BondingStarted(uint timestamp, uint duration);

    /**
     * @dev Function calculates amount of token out
     * Params:
     * - amountIn - token amount to be spended by user
     */
    function bondAmountOut(uint amountIn) external view returns(uint amountOut);

    /**
     * @dev Starts bonding period.
     *
     * Accessible by owner only!
     */
    function startBonding() external;

    /**
     * @dev Shows total amount of issued bonds by this contract.
     */
    function totalSupply() external view returns (uint);


    /**
     * @dev Releases sGTON token for user by it's `tokenId`.

     * Emits {Claim} event.
     */
    function claim(uint tokenId) external;
}
