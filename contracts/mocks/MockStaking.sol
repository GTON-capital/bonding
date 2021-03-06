//SPDX-License-Identifier: MIT
pragma solidity >=0.8.0;

import "./../interfaces/IStaking.sol";
import "./../interfaces/InitializableOwnable.sol";

contract MockStaking is InitializableOwnable, IStaking {

    /* ========== HELPER STRUCTURES ========== */

    struct UserInfo {
        uint amount;
        uint rewardDebt;
        uint accumulatedReward;
        uint lastHarvestTimestamp;
    }

    /* ========== CONSTANTS ========== */

    IERC20 public immutable stakingToken;

    string public name;
    string public symbol;
    uint public immutable harvestInterval;
    uint8 public immutable decimals;

    uint public constant calcDecimals = 1e14;
    uint public constant secondsInYear = 31557600;
    uint public constant aprDenominator = 10000;

    /* ========== STATE VARIABLES ========== */

    address public admin;
    bool public paused;
    bool public unstakePermitted;
    uint public aprBasisPoints;

    uint public amountStaked;
    uint public accumulatedRewardPerShare;
    uint public lastRewardTimestamp;

    mapping(address => UserInfo) public userInfo;
    mapping(address => mapping(address => uint)) public allowances;

    /* ========== CONSTRUCTOR ========== */

    constructor(
        IERC20 token_,
        string memory name_,
        string memory symbol_,
        uint aprBasisPoints_,
        uint harvestInterval_
    ) {
        initOwner(msg.sender);
        stakingToken = token_;
        name = name_;
        symbol = symbol_;
        aprBasisPoints = aprBasisPoints_;
        harvestInterval = harvestInterval_;
        lastRewardTimestamp = block.timestamp;
        decimals = IERC20Metadata(address(token_)).decimals();
    }

    /* ========== VIEWS ========== */

    function totalSupply() external view returns (uint256) {
        return amountStaked; 
    }

    function currentRewardDelta() public view returns (uint) {
        uint timeDelta = block.timestamp - lastRewardTimestamp;
        return (timeDelta * aprBasisPoints * calcDecimals) / (aprDenominator * secondsInYear);
    }

    function calculateRewardForStake(uint amount) internal view returns (uint) {
        return accumulatedRewardPerShare * amount / calcDecimals;
    }

    function balanceOf(address user_) external view returns(uint) {
        UserInfo storage user = userInfo[user_];
        uint updAccumulatedRewardPerShare = currentRewardDelta() + accumulatedRewardPerShare;

        uint acc = updAccumulatedRewardPerShare * user.amount / calcDecimals - user.rewardDebt;
        return user.accumulatedReward + acc + user.amount;
    }

    function allowance(address owner, address spender) external view returns (uint256) {
        return allowances[owner][spender];
    }

    /* ========== MUTATIVE FUNCTIONS ========== */

    function _approve(
        address owner,
        address spender,
        uint256 amount
    ) internal virtual {
        require(owner != address(0), "ERC20: approve from the zero address");
        require(spender != address(0), "ERC20: approve to the zero address");
        allowances[owner][spender] = amount;
        emit Approval(owner, spender, amount);
    }

    function approve(
        address spender, 
        uint amount
    ) external whenNotPaused virtual override returns (bool) {
        _approve(msg.sender, spender, amount);
        return true;
    }

    function _transfer(
        address sender_,
        address recipient_,
        uint amount
    ) internal {
        updateRewardPool();
        require(sender_ != address(0), "ERC20: transfer from the zero address");
        require(recipient_ != address(0), "ERC20: transfer to the zero address");

        UserInfo storage sender = userInfo[sender_];
        UserInfo storage recipient = userInfo[recipient_];
        require(amount <= sender.amount, "ERC20: transfer amount exceeds balance");

        sender.accumulatedReward += calculateRewardForStake(sender.amount) - sender.rewardDebt;
        sender.amount -= amount; 
        sender.rewardDebt = calculateRewardForStake(sender.amount);

        recipient.accumulatedReward += calculateRewardForStake(recipient.amount) - recipient.rewardDebt;
        recipient.amount += amount; 
        recipient.rewardDebt = calculateRewardForStake(recipient.amount);

        emit Transfer(sender_, recipient_, amount);
    }

    function transfer(
        address recipient, 
        uint256 amount
    ) external whenNotPaused virtual override returns (bool) {
        _transfer(msg.sender, recipient, amount);
        return true;
    } 

    function transferFrom(
        address spender,
        address recipient,
        uint256 amount
    ) external whenNotPaused virtual override returns (bool) {
        _transfer(spender, recipient, amount);
        uint256 currentAllowance = allowances[spender][msg.sender];
        require(currentAllowance >= amount, "ERC20: transfer amount exceeds allowance");
        _approve(spender, msg.sender, currentAllowance - amount);
        return true;
    }

    function updateRewardPool() public canUnstake {
        accumulatedRewardPerShare += currentRewardDelta();
        lastRewardTimestamp = block.timestamp;
    }

    function stake(
        uint amount, 
        address to
    ) external whenNotPaused {
        updateRewardPool();
        require(amount > 0, "Staking: Nothing to deposit");
        require(to != address(0));
        require(stakingToken.transferFrom(msg.sender, address(this), amount), "Staking: transfer failed");

        UserInfo storage user = userInfo[to];
        user.accumulatedReward += calculateRewardForStake(user.amount) - user.rewardDebt;
        amountStaked += amount;
        user.amount += amount;
        user.rewardDebt = calculateRewardForStake(user.amount);
        emit Transfer(address(0), to, amount);
    }

    function harvest(uint256 amount) external whenNotPaused {
        updateRewardPool();
        UserInfo storage user = userInfo[msg.sender];
        require(user.lastHarvestTimestamp + harvestInterval <= block.timestamp || 
            user.lastHarvestTimestamp == 0, "Staking: less than 24 hours since last harvest");
        user.lastHarvestTimestamp = block.timestamp;
        uint reward = calculateRewardForStake(user.amount);
        user.accumulatedReward += reward - user.rewardDebt;
        user.rewardDebt = reward;

        require(amount > 0, "Staking: Nothing to harvest");
        require(amount <= user.accumulatedReward, "Staking: Insufficient to harvest");
        user.accumulatedReward -= amount;
        require(stakingToken.transfer(msg.sender, amount), "Staking: transfer failed");
    }

    function unstake(
        address to, 
        uint256 amount
    ) external canUnstake {
        updateRewardPool();
        require(amount > 0, "Staking: Nothing to unstake");
        require(to != address(0));

        UserInfo storage user = userInfo[msg.sender];
        require(amount <= user.amount, "Staking: Insufficient share");
        user.accumulatedReward += calculateRewardForStake(user.amount) - user.rewardDebt;
        amountStaked -= amount;
        user.amount -= amount;
        user.rewardDebt = calculateRewardForStake(user.amount);

        require(stakingToken.transfer(to, amount), "Staking: Not enough token to transfer");
        emit Transfer(to, address(0), amount);
    }

    /* ========== RESTRICTED FUNCTIONS ========== */

    function setApr(uint aprBasisPoints_) external onlyOwner {
        updateRewardPool();
        uint oldAprBasisPoints = aprBasisPoints;
        aprBasisPoints = aprBasisPoints_;
        emit SetApr(oldAprBasisPoints, aprBasisPoints);
    }

    function togglePause() external onlyOwner {
        paused = !paused;
        emit Pause(paused);
    }

    function toggleUnstake() external onlyOwner {
        unstakePermitted = !unstakePermitted;
        emit UnstakePermit(unstakePermitted);
    }

    function withdrawToken(
        IERC20 tokenToWithdraw, 
        address to, 
        uint amount
    ) external onlyOwner {
        require(tokenToWithdraw.transfer(to, amount));
    }

    /* ========== MODIFIERS ========== */

    modifier whenNotPaused() {
        require(!paused, "Staking: contract paused.");
        _;
    }

    modifier canUnstake() {
        require(unstakePermitted || (!paused), "Staking: contract paused or unstake denied.");
        _;
    }
}
