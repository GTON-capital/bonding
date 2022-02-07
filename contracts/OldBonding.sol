//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
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

contract Bonding {
    IWETH public eth;
    IERC20 public gton;
    address public treasury;

    address public owner;
    AggregatorV3Interface public gtonPrice;
    bool public revertFlag;
    uint contractRequiredGtonBalance;
    Discounts[] public discounts;
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

    modifier onlyOwner() {
        require(msg.sender == owner,"not owner");
        _;
    }   

    
    modifier notReverted() {
        require(!revertFlag,"reverted");
        _;
    }   

    function toggleRevert() public onlyOwner {
        revertFlag = !revertFlag;
    }

    function transferOwnership(address newOwner) public onlyOwner {
        owner = newOwner;
    }

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
        uint discountDiv,
        uint minimalAmount
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

    constructor (
        IWETH _eth,
        IERC20 _gton,
        address _treasury,
        address _owner
    ) {
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

    function createBond (
            uint bondId, 
            uint tokenId, 
            address tokenAddress, 
            uint tokenAmount,
            uint discountMul,
            uint discountDiv
    ) public notReverted {
        Discounts memory disc = discounts[bondId];
        AllowedTokens memory tok = allowedTokens[tokenId];
        require(tok.token == tokenAddress, "ops");
        require(disc.discountMul == discountMul && disc.discountDiv == discountDiv, "ops");
        require(tok.token == tokenAddress, "ops");
        require(tokenAmount > tok.minimalAmount,"amount lower than minimal");
        require(IERC20(tok.token).transferFrom(msg.sender,address(this),tokenAmount),"not enough allowance");

        uint amount = getTokenAmountWithDiscount(
            disc.discountMul,
            disc.discountDiv,
            tok.price,
            tokenAmount
        );

        UserUnlock[] storage user = userUnlock[msg.sender];
        user.push(UserUnlock({
            rewardDebt: 0,
            amount: amount,
            startBlock: block.number,
            delta: disc.delta
        }));

        // send to candyshop for treasury
        require(IERC20(tok.token).approve(address(tok.can),tokenAmount),"cant approve");
        tok.can.mintFor(treasury,tokenAmount);
        contractRequiredGtonBalance += amount;
    }

    function claimBond(
        uint amount,
        uint bondId,
        address to
    ) public notReverted {
        // optimistycally transfer gton
        require(IERC20(gton).transfer(to,amount));

        UserUnlock storage user = userUnlock[msg.sender][bondId];
        uint currentUnlock = user.delta * (block.number - user.startBlock) / user.amount;
        require(amount + user.rewardDebt <= currentUnlock,"not enough unlock");
        user.rewardDebt += amount;
        contractRequiredGtonBalance -= amount;

        // rm this bond if it is over
        if (amount + user.rewardDebt == currentUnlock && block.number >= user.startBlock + user.delta) {
            userUnlock[msg.sender][bondId] = userUnlock[msg.sender][userUnlock[msg.sender].length];
            userUnlock[msg.sender].pop();
        }
    }

    function claimBondTotal(
        address to
    ) public notReverted {
        // optimistycally transfer gton

        uint accamulatedAmount = 0;
        UserUnlock[] storage user = userUnlock[msg.sender];
        for (uint i = 0; i < user.length; i++) {
            uint currentUnlock = user[i].delta * (block.number - user[i].startBlock) / user[i].amount;
            accamulatedAmount += currentUnlock - user[i].rewardDebt;
            user[i].rewardDebt = currentUnlock;
        }
        require(IERC20(gton).transfer(to,accamulatedAmount));
        contractRequiredGtonBalance -= accamulatedAmount;

        // rm  bonds if they are over
        for(uint i = 0; i < user.length;) {
            if (block.number >= user[i].startBlock + user[i].delta) {
                userUnlock[msg.sender][i] = userUnlock[msg.sender][userUnlock[msg.sender].length];
                userUnlock[msg.sender].pop();
            }  else {
                i++;
            }
        }
    }
}