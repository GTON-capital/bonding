//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/IStaking.sol";
import "./interfaces/IWETH.sol";
import './libraries/UniswapV2Library.sol';
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

interface ICan {
    function toggleRevert() external;
    function transferOwnership(address newOwner) external;
    function emergencyTakeout(IERC20 _token, address _to, uint _amount) external;
    function changeCanFee(uint _fee) external;
    function updateCan () external;
    function mintFor(address _user, uint _providedAmount) external;
    function burnFor(address _user, uint _providedAmount, uint _rewardAmount) external;
    function transfer(address _from, address _to, uint _providingAmount, uint _rewardAmount) external;
    function emergencySendToFarming(uint _amount) external;
    function emergencyGetFromFarming(uint _amount) external;
    function canInfo() external returns(
        uint totalProvidedTokenAmount,
        uint totalFarmingTokenAmount,
        uint accRewardPerShare,
        uint totalRewardsClaimed,
        uint farmId,
        address farm,
        address router,
        address lpToken,
        address providingToken,
        address rewardToken,
        uint fee
    );
}

contract Bounding is IERC20 {
    IWETH public eth;
    IERC20 public gton;
    address public treasury;
    IStaking public staking;

    address public owner;
    AggregatorV3Interface public gtonPrice;
    bool public revertFlag;
    uint public contractRequiredGtonShare;
    Discounts[] public discounts;
    uint public allowedRewardPerTry;
    mapping (address => UserUnlock[]) public userUnlock;
    // address of token => address of price sc

    AllowedTokens[] public allowedTokens;

    struct AllowedTokens {
        AggregatorV3Interface price;
        address token;
        ICan can; 
        uint minimalAmount;
    }

    struct UserUnlock {
        uint rewardDebt;
        uint amount;
        uint startBlock;
        uint delta;
    }

    struct Discounts {
        uint delta;
        uint discountMul;
        uint discountDiv;
    }

    modifier onlyOwner() {require(msg.sender == owner,"not owner");_;}   
    modifier notReverted() {require(!revertFlag,"reverted");_;}   
    function toggleRevert() public onlyOwner {revertFlag = !revertFlag;}
    function transferOwnership(address newOwner) public onlyOwner {owner = newOwner;}

    function addAllowedToken(
        AggregatorV3Interface price,
        ICan can,
        uint minimalAmount
    ) public onlyOwner {
        (,,,,,,,,address token,,) = can.canInfo();
        allowedTokens.push(AllowedTokens({
            price: price,
            token: token,
            can: can,
            minimalAmount: minimalAmount
        }));
    }

    function emergencyTokenWithdraw(
        address token,
        uint amount,
        address to
    ) public onlyOwner {
        IERC20(token).transfer(to,amount);
    }

    function addDiscount(
        uint delta,
        uint discountMul,
        uint discountDiv
    ) public onlyOwner {
        discounts.push(Discounts({
            delta: delta,
            discountMul: discountMul,
            discountDiv: discountDiv
        }));
    }

    function rmDiscount(
        uint id
    ) public onlyOwner {
        discounts[id] = discounts[discounts.length];
        discounts.pop();
    }

    function changeDiscount(
        uint id,
        uint delta,
        uint discountMul,
        uint discountDiv
    ) public onlyOwner {
        discounts[id] = Discounts({
            delta: delta,
            discountMul: discountMul,
            discountDiv: discountDiv
        });
    }

    function changeAllowedToken(
        uint id,
        AggregatorV3Interface price,
        ICan can,
        uint minimalAmount
    ) public onlyOwner {
        (,,,,,,,,address token,,) = can.canInfo();
        allowedTokens[id] = AllowedTokens({
            price: price,
            token: token,
            can: can,
            minimalAmount: minimalAmount
        });
    }

    function rmAllowedToken(
        uint id
    ) public onlyOwner {
        allowedTokens[id] = allowedTokens[allowedTokens.length];
        allowedTokens.pop();
    }

    function changeAllowedRewardPerTry(
        uint _allowedRewardPerTry
    ) public onlyOwner {
        allowedRewardPerTry = _allowedRewardPerTry;
    }

    constructor (
        IWETH _eth,
        IERC20 _gton,
        address _treasury,
        address _owner,
        uint _allowedRewardPerTry
    ) {
        allowedRewardPerTry = _allowedRewardPerTry;
        eth = _eth;
        gton = _gton;
        treasury = _treasury;
        owner = _owner;
    }

    function getTokenAmountWithDiscount(
        uint discountMul,
        uint discountDiv,
        AggregatorV3Interface tokenPrice,
        uint tokenAmount
    ) public view returns(uint) {
        uint8 gtonDecimals = gtonPrice.decimals();
        (,int256 gtonPriceUSD,,,) = gtonPrice.latestRoundData();

        uint8 tokenDecimals = tokenPrice.decimals();
        (,int256 tokenPriceUSD,,,) = tokenPrice.latestRoundData();

        return uint(int256(tokenAmount) * tokenPriceUSD * int256(uint(gtonDecimals)) * int256(discountMul)
            / gtonPriceUSD / int256(uint(tokenDecimals)) / int256(discountDiv));
    }

    function createBound (
            uint boundId, 
            uint tokenId, 
            address tokenAddress, 
            uint tokenAmount,
            uint discountMul,
            uint discountDiv
    ) public notReverted {
        Discounts memory disc = discounts[boundId];
        AllowedTokens memory tok = allowedTokens[tokenId];
        require(tok.token == tokenAddress, "ops");
        require(disc.discountMul == discountMul && disc.discountDiv == discountDiv, "ops");
        require(tokenAmount > tok.minimalAmount,"amount lower than minimal");
        require(IERC20(tok.token).transferFrom(msg.sender,address(this),tokenAmount),"not enough allowance");

        uint amount = getTokenAmountWithDiscount(
            disc.discountMul,
            disc.discountDiv,
            tok.price,
            tokenAmount
        );
        // require that you havent claimed more than x percent of total supply of gton on this contract
        require(amount * 10000 <= gton.balanceOf(address(this)) * allowedRewardPerTry, "too much gton");
        gton.approve(address(staking),amount);
        staking.mint(amount,address(this));
        emit Transfer(address(0),msg.sender,amount);
        uint share = staking.balanceToShare(amount);

        UserUnlock[] storage user = userUnlock[msg.sender];
        user.push(UserUnlock({
            rewardDebt: 0,
            amount: share,
            startBlock: block.number,
            delta: disc.delta
        }));

        // send to candyshop for treasury
        require(IERC20(tok.token).approve(address(tok.can),tokenAmount),"cant approve");
        tok.can.mintFor(treasury,tokenAmount);
        contractRequiredGtonShare += share;
    }

    function createBoundByAdmin (
            uint amount,
            uint delta,
            address _user
    // todo: add admins and modifier
    ) public notReverted {
        gton.transferFrom(msg.sender,address(this),amount);
        gton.approve(address(staking),amount);
        staking.mint(amount,address(this));
        emit Transfer(address(0),msg.sender,amount);
        uint share = staking.balanceToShare(amount);

        UserUnlock[] storage user = userUnlock[_user];
        user.push(UserUnlock({
            rewardDebt: 0,
            amount: share,
            startBlock: block.number,
            delta: delta
        }));
        contractRequiredGtonShare += share;
    }

    function accamulateUserRewards(
        address _user
    ) internal returns(uint accamulatedAmount) {
        UserUnlock[] storage user = userUnlock[_user];
        for (uint i = 0; i < user.length;) {
            uint currentUnlock = 
                user[i].delta * (block.number - user[i].startBlock) / user[i].amount;
            accamulatedAmount += currentUnlock - user[i].rewardDebt;
            if (block.number >= user[i].startBlock + user[i].delta) {
                userUnlock[msg.sender][i] = userUnlock[msg.sender][userUnlock[msg.sender].length];
                userUnlock[msg.sender].pop();
            } else {
                user[i].rewardDebt = currentUnlock;
                i++;
            }
        }
    }

    function showUserRewards(address _user) public view returns(uint accamulatedAmount) {
        UserUnlock[] memory user = userUnlock[_user];
        for (uint i = 0; i < user.length;) {
            uint currentUnlock = 
                user[i].delta * (block.number - user[i].startBlock) / user[i].amount;
            accamulatedAmount += currentUnlock - user[i].rewardDebt;
        }
    }

    function claimBoundTotal(address to) public notReverted {
        uint accamulatedAmount = accamulateUserRewards(msg.sender);
        staking.transferShare(to,accamulatedAmount);
        contractRequiredGtonShare -= accamulatedAmount;
    }

    //smart token proxy here
    function name() public view returns (string memory) {
        return staking.name();
    }
    function symbol() public view returns (string memory) {
        return staking.symbol();
    }
    function decimals() public view returns (uint8) {
        return staking.decimals();
    }
    function totalSupply() public view returns (uint) {
        return staking.totalSupply();   
    }
    function balanceOf(address owner) public view returns (uint) {
        return staking.shareToBalance(showUserRewards(owner)) + staking.balanceOf(owner);
    }
    function allowance(address owner, address spender) public view returns (uint) {
        return staking.allowance(owner,spender);   
    }
    function approve(address spender, uint value) public returns (bool) {
        emit Approval(msg.sender,spender,value);
        claimBoundTotal(msg.sender);
        (, bytes memory result) = 
            address(staking).delegatecall(abi.encodeWithSignature("approve(address,uint)", spender, value));
        return abi.decode(result, (bool));
    }
    function transfer(address to, uint value) public returns (bool) {
        emit Transfer(msg.sender,to,value);
        claimBoundTotal(msg.sender);
        (, bytes memory result) = 
            address(staking).delegatecall(abi.encodeWithSignature("transfer(address,uint)", to, value));
        return abi.decode(result, (bool));
    }
    function transferFrom(address from, address to, uint value) public returns (bool) {
        emit Transfer(from,to,value);
        claimBoundTotal(msg.sender);
        (, bytes memory result) = 
            address(staking).delegatecall(abi.encodeWithSignature("transferFrom(address,address,uint)",from, to, value));
        return abi.decode(result, (bool));
    }
    function mint(uint _amount, address _to) public {
        gton.transferFrom(msg.sender,address(this),_amount);
        gton.approve(address(staking),_amount);
        claimBoundTotal(msg.sender);
        staking.mint(_amount,_to);
        emit Transfer(address(0),_to,_amount);
    }
    function burn(address _to, uint256 _share) public {
        emit Transfer(msg.sender,address(0),staking.shareToBalance(_share));
        claimBoundTotal(msg.sender);
        address(staking).delegatecall(abi.encodeWithSignature("burn(address,uint256)",_to, _share));
    }
}
