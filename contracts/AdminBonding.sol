//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import { IBondStorage } from "./interfaces/IBondStorage.sol";

import { AggregatorV3Interface } from "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import { Staking } from "@gton/staking/contracts/Staking.sol";

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { ERC721Holder } from "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";


contract AdminBonding is Ownable, ERC721Holder {

    constructor(
        IBondStorage _bondStorage, 
        ERC20 _gton,
        Staking _sgton
        ) {
            bondStorage =  _bondStorage;
            gton =  _gton;
            sgton = _sgton;
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
    Staking immutable public sgton;
    IBondStorage immutable public bondStorage;

    /* ========== VIEWS ========== */

    function isActiveBond(uint id) public view returns(bool) {
        return activeBonds[id].isActive;
    }

    /**
     * Function returns total amount of bonds issued by this contract
     */
    function totalSupply() public view returns(uint) {
        return bondCounter;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    /**
     * Function receives the bond from user and updates users balance with sgton
     */
    function claim(uint tokenId) public {
        // No need to add checks if bond was issued on this contract because the id of bond is unique
        require(isActiveBond(tokenId), "Bonding: Cannot claim inactive bond");
        bondStorage.safeTransferFrom(msg.sender, address(this), tokenId);
        BondData storage bond = activeBonds[tokenId];   
        require(bond.releaseTimestamp <= block.timestamp, "Bonding: Bond is locked to claim now");
        bond.isActive = false;
        gton.approve(address(sgton), bond.releaseAmount);
        sgton.stake(bond.releaseAmount, msg.sender);
        emit Claim(msg.sender, tokenId);
    }

     /* ========== RESTRICTED ========== */
    
    function mint(uint bondReward, address user, uint releaseTimestamp, bytes memory _bondType) public onlyOwner returns(uint id) {
        id = bondStorage.mint(user, releaseTimestamp, bondReward);
        activeBonds[id] = BondData(true, block.timestamp, releaseTimestamp, _bondType, bondReward);

        bondCounter++;
        emit Mint(id, user);
        emit MintData(address(gton), bondReward, releaseTimestamp, _bondType);
    }

    function transferToken(ERC20 _token, address user) public onlyOwner {
        _token.transfer(user, _token.balanceOf(address(this)));
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
