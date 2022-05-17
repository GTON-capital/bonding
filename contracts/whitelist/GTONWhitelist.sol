//SPDX-License-Identifier: MIT
pragma solidity 0.8.13;

import { InitializableOwnable } from "../interfaces/InitializableOwnable.sol";
import { IWhitelist } from "../interfaces/IWhitelist.sol";

interface ContractWithBalance {
    function balanceOf(address account) external view returns (uint256);
}

contract GTONWhitelist is InitializableOwnable, IWhitelist {

    /* ========== STATE VARIABLES ========== */

    uint baseAllocation = 100_000 * 1e18;

    address[] public nfts;

    address[] public tokens;
    mapping(address => uint) public tokenThresholds;

    mapping(address => bool) whitelistActivated;
    mapping(address => uint) userAllocations;

    uint8 maxReferrals = 3;
    mapping(address => uint8) referralsCount;
    mapping(address => bool) userWasReferred;

    constructor(
        address[] memory nfts_,
        address[] memory tokens_,
        uint[] memory tokenThresholds_
    ) {
        require(tokens_.length == tokenThresholds_.length, "Corrupt token data");
        initOwner(msg.sender);
        nfts = nfts_;
        tokens = tokens_;
        for (uint i = 0; i < tokens_.length; i++) {
            tokenThresholds[tokens_[i]] = tokenThresholds_[i];
        }
    }

    /* ========== VIEWS ========== */

    function isWhitelisted(address user) public view returns(bool) {
        if (userAllocations[user] > 0) {
            return true;
        } else if (!whitelistActivated[user]) {
            for (uint i = 0; i < nfts.length; i++) {
                if (ContractWithBalance(nfts[i]).balanceOf(user) > 0) {
                    return true;
                }
            }
            for (uint i = 0; i < tokens.length; i++) {
                address token = tokens[i];
                if (ContractWithBalance(token).balanceOf(user) > tokenThresholds[token]) {
                    return true;
                }
            }
        }
        return false;
    }

    function allowedAllocation(address user) public view returns(uint) {
        if (userAllocations[user] > 0) {
            return userAllocations[user];
        } else if (!whitelistActivated[user] && isWhitelisted(user)) {
            return baseAllocation;
        }
        return 0;
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function updateBaseAllocation(uint allocation) external onlyOwner {
        baseAllocation = allocation;
        emit BaseAllocationUpdated(allocation);
    }

    function addCollection(address collection) external onlyOwner {
        nfts.push(collection);
        emit CollectionAdded(collection);
    }

    function removeCollection(address collection) external onlyOwner {
        for (uint i = 0; i < nfts.length; i++) {
            if (nfts[i] == collection) {
                nfts[i] = nfts[nfts.length-1];
                nfts.pop();
                emit CollectionRemoved(collection);
                break;
            }
        }
    }

    function addToken(address token, uint threshold) external onlyOwner {
        tokens.push(token);
        tokenThresholds[token] = threshold;
        emit TokenAdded(token, threshold);
    }

    function removeToken(address token) external onlyOwner {
        for (uint i = 0; i < tokens.length; i++) {
            if (tokens[i] == token) {
                tokens[i] = tokens[tokens.length-1];
                tokens.pop();
                tokenThresholds[token] = 0;
                emit TokenRemoved(token);
                break;
            }
        }
    }

    function updateTokenThreshold(
        address token, 
        uint threshold
    ) external onlyOwner {
        tokenThresholds[token] = threshold;
        emit TokenThresholdUpdated(token, threshold);
    }

    function updateAllocation(address user, uint allocation) external onlyAdminOrOwner {
        updateUserAllocation(user, allocation);
    }

    function updateUserAllocation(address user, uint allocation) internal {
        userAllocations[user] = allocation;
        whitelistActivated[user] = true;
        emit UserAllocationUpdated(user, allocation);
    }

    function setMaxReferrals(uint8 maxReferrals_) external {
        maxReferrals = maxReferrals_;
        emit MaxReferralsUpdated(maxReferrals_);
    }

    function referFriend(address user) external {
        require(isWhitelisted(msg.sender) || whitelistActivated[msg.sender], "You are not whitelisted");
        require(!userWasReferred[msg.sender], "You were referred yourself");
        require(referralsCount[msg.sender] < maxReferrals, "Too many referrals");
        require(!isWhitelisted(user), "Friend already on whitelist");
        referralsCount[msg.sender] += 1;
        userWasReferred[user] = true;
        updateUserAllocation(user, baseAllocation);
        emit Referral(msg.sender, user);
    }

    /* ========== EVENTS ========== */

    event BaseAllocationUpdated(
        uint indexed allocation
    );

    event CollectionAdded(
        address indexed collection
    );
    event CollectionRemoved(
        address indexed collection
    );

    event TokenAdded(
        address indexed token, 
        uint indexed threshold
    );
    event TokenRemoved(
        address indexed token
    );
    event TokenThresholdUpdated(
        address indexed token, 
        uint indexed threshold
    );

    event MaxReferralsUpdated(
        uint8 indexed value
    );
    event Referral(
        address indexed referrer, 
        address indexed friend
    );

    event UserAllocationUpdated(
        address indexed user, 
        uint indexed allocation
    );
}
