//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { IBondStorage } from "./interfaces/IBondStorage.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { IStaking } from "./interfaces/IStaking.sol";
import { InitializableOwnable } from "./interfaces/InitializableOwnable.sol";

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract AdminBonding is InitializableOwnable, ERC721Holder {

    constructor(
        IBondStorage bondStorage_, 
        ERC20 gton_,
        IStaking sgton_
        ) {
            initOwner(msg.sender);
            bondStorage =  bondStorage_;
            gton =  gton_;
            sgton = sgton_;
        }

    uint public bondCounter;
    mapping (uint => BondData) public activeBonds;

    struct BondData {
        bool isActive;
        uint issueTimestamp;
        uint releaseTimestamp;
        bytes bondType;
        uint releaseAmount;
    }

    ERC20 immutable  public gton;
    IStaking immutable public sgton;
    IBondStorage immutable public bondStorage;

    /* ========== VIEWS ========== */

    function isActiveBond(uint id) public view returns(bool) {
        return activeBonds[id].isActive;
    }

    /**
     * Function returns total amount of bonds issued by this contract
     */
    function totalSupply() external view returns(uint) {
        return bondCounter;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * Function receives the bond from user and updates users balance with sgton
     */
    function claim(uint tokenId) external {
        // No need to add checks if bond was issued on this contract because the id of bond is unique
        require(isActiveBond(tokenId), "Bonding: Cannot claim inactive bond");
        BondData storage bond = activeBonds[tokenId];
        bond.isActive = false;

        require(bond.releaseTimestamp <= block.timestamp, "Bonding: Bond is locked to claim now");
        bondStorage.safeTransferFrom(msg.sender, address(this), tokenId);
        
        if (!(gton.approve(address(sgton), bond.releaseAmount))) { revert(); }
        sgton.stake(bond.releaseAmount, msg.sender);
        emit Claim(msg.sender, tokenId);
    }

     /* ========== RESTRICTED ========== */
    
    function mint(uint bondReward, address user, uint releaseTimestamp, bytes memory _bondType) external onlyOwner returns(uint id) {
        id = bondStorage.mint(user, releaseTimestamp, bondReward);
        activeBonds[id] = BondData(true, block.timestamp, releaseTimestamp, _bondType, bondReward);

        bondCounter++;
        emit Mint(id, user);
        emit MintData(address(gton), bondReward, releaseTimestamp, _bondType);
    }

    function transferToken(ERC20 _token, address user) external onlyOwner {
        if (!(_token.transfer(user, _token.balanceOf(address(this))))) { revert(); }
    }

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
    event MintData(address indexed asset, uint allocation, uint releaseDate, bytes bondType);

    /**
     * @dev Emitted when `user` claims `tokenId` bond.
     */
    event Claim(address indexed user, uint tokenId);
}
