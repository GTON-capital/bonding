//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

interface IBondingMinter {

    /**
     * @dev Emitted when the bond period opens. 
     * Emits bond period bordes with `startTimestamp` and `endTimestamp`.
     */
    event StartBonding(uint startTimestamp, uint endTimestamp);

    /**
     * @dev Emitted when the bond is minted for `user` with `tokenId` id. 
     */
    event Mint(address indexed tokenId, address indexed user);

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
     * @dev Mints new token for message sender.
     * 
     * Emits {Mint} and {MintData} events
     */
    function mint() external payable returns (uint tokenId);
}