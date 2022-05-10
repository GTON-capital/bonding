//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { InitializableOwnable } from "./interfaces/InitializableOwnable.sol";
import { IWhitelist } from "./interfaces/IWhitelist.sol";

interface NFTContract {
    function balanceOf(address account) external view returns (uint256);
}

contract WhitelistWithNFT is InitializableOwnable, IWhitelist {

    /* ========== STATE VARIABLES ========== */

    address[] public whitelistedNFTs;
    mapping(address => uint) public nftCollectionAllowance;
    mapping(address => bool) whitelistActivated;
    mapping(address => uint) whitelist;

    constructor() {
        initOwner(msg.sender);
    }

    /* ========== VIEWS ========== */

    function isWhitelisted(address user) external view returns(bool) {
        if (whitelist[user] > 0) {
            return true;
        } else if (!whitelistActivated[user]) {
            for (uint i = 0; i < whitelistedNFTs.length; i++) {
                if (NFTContract(whitelistedNFTs[i]).balanceOf(user) > 0) {
                    return true;
                }
            }
        }
        return false;
    }

    function allowedAllocation(address user) external view returns(uint) {
        if (whitelist[user] > 0) {
            return whitelist[user];
        } else if (!whitelistActivated[user]) {
            uint allocation = 0;
            for (uint i = 0; i < whitelistedNFTs.length; i++) {
                address collectionAddress = whitelistedNFTs[i];
                NFTContract nft = NFTContract(whitelistedNFTs[i]);
                if (nft.balanceOf(user) > 0) {
                    uint collectionAllocation = nftCollectionAllowance[collectionAddress];
                    allocation = collectionAllocation > allocation ? collectionAllocation : allocation;
                }
            }
            return allocation;
        }
        return 0;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function addCollection(address collection, uint allocation) external onlyOwner {
        whitelistedNFTs.push(collection);
        nftCollectionAllowance[collection] = allocation;
        emit CollectionAdded(collection, allocation);
    }

    function removeCollection(address collection) external onlyOwner {
        for (uint i = 0; i < whitelistedNFTs.length; i++) {
            if (whitelistedNFTs[i] == collection) {
                whitelistedNFTs[i] = whitelistedNFTs[whitelistedNFTs.length-1];
                whitelistedNFTs.pop();
                nftCollectionAllowance[collection] = 0;
                emit CollectionRemoved(collection);
                break;
            }
        }
    }

    function updateCollectionAllocation(address collection, uint allocation) external onlyOwner {
        nftCollectionAllowance[collection] = allocation;
        emit CollectionAllocationUpdated(collection, allocation);
    }

    function updateAllocation(address user, uint allocation) external onlyAdminOrOwner {
        whitelist[user] = allocation;
        whitelistActivated[user] = true;
        emit UserAllocationUpdated(user, allocation);
    }

    /* ========== EVENTS ========== */

    event CollectionAdded(address collection, uint allocation);
    event CollectionRemoved(address collection);
    event CollectionAllocationUpdated(address collection, uint allocation);
    event UserAllocationUpdated(address user, uint allocation);
}
