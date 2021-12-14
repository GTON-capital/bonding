//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./interfaces/IERC20.sol";
import "./interfaces/ICan.sol";
import '@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol';
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Bounding {
    address public owner;
    bool public revertFlag;
    address public treasury;

    IERC20 public gton;
    AggregatorV3Interface public gtonPrice;

    uint contractRequiredGtonBalance;
    Discounts[] public discounts;
    AllowedTokens[] public allowedTokens;
    mapping (address => UserUnlock[]) public userUnlock;
    // address of token => address of price sc

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

    constructor (
        IERC20 _gton,
        address _treasury
    ) {
        gton = _gton;
        treasury = _treasury;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner,"Bounder: permitted to owner only.");
        _;
    }   
    
    modifier notReverted() {
        require(!revertFlag,"Bounder: reverted flag on.");
        _;
    }   

    function toggleRevert() public onlyOwner {
        revertFlag = !revertFlag;
        emit RevertFlag(revertFlag);
    }

    function transferOwnership(address newOwner) public onlyOwner {
        address oldOwner = owner;
        owner = newOwner;
        emit SetOwner(oldOwner, newOwner);
    }

    function discountsLength() public view returns(uint) {
        return discounts.length;
    }

    function tokensLength() public view returns(uint) {
        return allowedTokens.length;
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

    function rmDiscount(uint id) public onlyOwner {
        discounts[id] = discounts[discounts.length - 1];
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


    function rmAllowedToken(uint id) public onlyOwner {
        allowedTokens[id] = allowedTokens[allowedTokens.length - 1];
        allowedTokens.pop();
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

    function createBound(
            uint boundId, 
            uint tokenId, 
            address tokenAddress, 
            uint tokenAmount,
            uint discountMul,
            uint discountDiv
    ) public notReverted {
        Discounts memory disc = discounts[boundId];
        AllowedTokens memory tok = allowedTokens[tokenId];
        require(tok.token == tokenAddress, "Bounding: wrong token address.");
        require(disc.discountMul == discountMul && disc.discountDiv == discountDiv, "Bounding: discound policy has changed.");
        require(tokenAmount > tok.minimalAmount,"Bounding: amount lower than minimal");
        require(IERC20(tok.token).transferFrom(msg.sender,address(this),tokenAmount),"Bounding: not enough allowance.");

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
        require(IERC20(tok.token).approve(address(tok.can),tokenAmount),"Bounding: Error when approve token");
        tok.can.mintFor(treasury,tokenAmount);
        contractRequiredGtonBalance += amount;
    }

    function claimBound(
        uint amount,
        uint boundId,
        address to
    ) public notReverted {
        // optimistycally transfer gton
        require(IERC20(gton).transfer(to,amount));

        UserUnlock storage user = userUnlock[msg.sender][boundId];
        uint currentUnlock = user.delta * (block.number - user.startBlock) / user.amount;
        require(amount + user.rewardDebt <= currentUnlock,"not enough unlock");
        user.rewardDebt += amount;
        contractRequiredGtonBalance -= amount;

        // rm this bound if it is over
        if (amount + user.rewardDebt == currentUnlock && block.number >= user.startBlock + user.delta) {
            userUnlock[msg.sender][boundId] = userUnlock[msg.sender][userUnlock[msg.sender].length - 1];
            userUnlock[msg.sender].pop();
        }
    }

    function claimBoundTotal(address to) public notReverted {
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

        // rm  bounds if they are over
        for(uint i = 0; i < user.length;) {
            if (block.number >= user[i].startBlock + user[i].delta) {
                userUnlock[msg.sender][i] = userUnlock[msg.sender][userUnlock[msg.sender].length - 1];
                userUnlock[msg.sender].pop();
            }  else {
                i++;
            }
        }
    }

    event RevertFlag(bool flag);
    event SetOwner(address oldOwner, address newOwner);
}