//SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "hardhat/console.sol";

import "./interfaces/IERC20.sol";
import "./interfaces/ICan.sol";
import "@uniswap/v2-core/contracts/interfaces/IUniswapV2Factory.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

contract Bounding {
    address public owner;
    bool public revertFlag;
    address public treasury;

    IERC20 public gton;
    AggregatorV3Interface public gtonPrice;

    uint256 contractRequiredGtonBalance;
    Discounts[] public discounts;
    AllowedTokens[] public allowedTokens;
    mapping(address => UserUnlock[]) public userUnlock;
    // address of token => address of price sc

    struct AllowedTokens {
        AggregatorV3Interface price;
        address token;
        ICan can;
        uint256 minimalAmount;
    }

    struct UserUnlock {
        uint256 rewardDebt;
        uint256 amount;
        uint256 startBlock;
        uint256 delta;
    }

    struct Discounts {
        uint256 delta;
        uint256 discountMul;
        uint256 discountDiv;
    }

    constructor(
        IERC20 _gton,
        address _treasury,
        AggregatorV3Interface _gtonPrice
    ) {
        gtonPrice = _gtonPrice;
        gton = _gton;
        treasury = _treasury;
        owner = msg.sender;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Bounder: permitted to owner only.");
        _;
    }

    modifier notReverted() {
        require(!revertFlag, "Bounder: reverted flag on.");
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

    function discountsLength() public view returns (uint256) {
        return discounts.length;
    }

    function tokensLength() public view returns (uint256) {
        return allowedTokens.length;
    }

    function boundsLength(address user) public view returns (uint256) {
        return userUnlock[user].length;
    }

    function addDiscount(
        uint256 delta,
        uint256 discountMul,
        uint256 discountDiv
    ) public onlyOwner {
        discounts.push(
            Discounts({
                delta: delta,
                discountMul: discountMul,
                discountDiv: discountDiv
            })
        );
    }

    function rmDiscount(uint256 id) public onlyOwner {
        discounts[id] = discounts[discounts.length - 1];
        discounts.pop();
    }

    function changeDiscount(
        uint256 id,
        uint256 delta,
        uint256 discountMul,
        uint256 discountDiv
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
        uint256 minimalAmount
    ) public onlyOwner {
        (, , , , , , , , address token, , ) = can.canInfo();
        allowedTokens.push(
            AllowedTokens({
                price: price,
                token: token,
                can: can,
                minimalAmount: minimalAmount
            })
        );
    }

    function rmAllowedToken(uint256 id) public onlyOwner {
        allowedTokens[id] = allowedTokens[allowedTokens.length - 1];
        allowedTokens.pop();
    }

    function changeAllowedToken(
        uint256 id,
        AggregatorV3Interface price,
        ICan can,
        uint256 minimalAmount
    ) public onlyOwner {
        (, , , , , , , , address token, , ) = can.canInfo();
        allowedTokens[id] = AllowedTokens({
            price: price,
            token: token,
            can: can,
            minimalAmount: minimalAmount
        });
    }

    function getTokenAmountWithDiscount(
        uint256 discountMul,
        uint256 discountDiv,
        AggregatorV3Interface tokenPrice,
        uint256 tokenAmount
    ) public view returns (uint256) {
        uint8 gtonDecimals = gtonPrice.decimals();
        (, int256 gtonPriceUSD, , , ) = gtonPrice.latestRoundData();

        uint8 tokenDecimals = tokenPrice.decimals();
        (, int256 tokenPriceUSD, , , ) = tokenPrice.latestRoundData();

        return
            uint256(
                (int256(tokenAmount) *
                    tokenPriceUSD *
                    int256(uint256(gtonDecimals)) *
                    int256(discountMul)) /
                    gtonPriceUSD /
                    int256(uint256(tokenDecimals)) /
                    int256(discountDiv)
            );
    }

    function createBound(
        uint256 boundId,
        uint256 tokenId,
        address tokenAddress,
        uint256 tokenAmount,
        uint256 discountMul,
        uint256 discountDiv
    ) public notReverted {
        Discounts memory disc = discounts[boundId];
        AllowedTokens memory tok = allowedTokens[tokenId];
        require(tok.token == tokenAddress, "Bounding: wrong token address.");
        require(
            disc.discountMul == discountMul && disc.discountDiv == discountDiv,
            "Bounding: discound policy has changed."
        );
        require(
            tokenAmount >= tok.minimalAmount,
            "Bounding: amount lower than minimal"
        );
        require(
            IERC20(tok.token).transferFrom(
                msg.sender,
                address(this),
                tokenAmount
            ),
            "Bounding: not enough allowance."
        );

        uint256 amount = getTokenAmountWithDiscount(
            disc.discountMul,
            disc.discountDiv,
            tok.price,
            tokenAmount
        );

        UserUnlock[] storage user = userUnlock[msg.sender];
        user.push(
            UserUnlock({
                rewardDebt: 0,
                amount: amount,
                startBlock: block.number,
                delta: disc.delta
            })
        );

        // send to candyshop for treasury
        require(
            IERC20(tok.token).approve(address(tok.can), tokenAmount),
            "Bounding: Error when approve token"
        );
        tok.can.mintFor(treasury, tokenAmount);
        contractRequiredGtonBalance += amount;
    }

    function claimBound(
        uint256 amount,
        uint256 boundId,
        address to
    ) public notReverted {
        // optimistycally transfer gton
        require(IERC20(gton).transfer(to, amount));

        UserUnlock storage user = userUnlock[msg.sender][boundId];
        uint256 currentUnlock;
        if ((block.number - user.startBlock) >= user.delta) {
            currentUnlock = user.amount;
        } else {
            currentUnlock =
                (user.amount * (block.number - user.startBlock)) /
                user.delta;
        }
        require(
            amount + user.rewardDebt <= currentUnlock,
            "Bounding: not enough of unlocked token."
        );
        contractRequiredGtonBalance -= amount;
        user.rewardDebt += amount;

        // rm this bound if it is over
        if (
            user.rewardDebt == currentUnlock &&
            block.number >= user.startBlock + user.delta
        ) {
            uint256 lastId = userUnlock[msg.sender].length - 1;
            userUnlock[msg.sender][boundId] = userUnlock[msg.sender][lastId]; // case when id == 0
            userUnlock[msg.sender].pop();
        }
    }

    function claimBoundTotal(address to) public notReverted {
        uint256 accumulatedAmount = 0;
        UserUnlock[] storage user = userUnlock[msg.sender];
        for (uint256 i = 0; i < user.length; i++) {
            uint256 currentUnlock;
            if ((block.number - user[i].startBlock) >= user[i].delta) {
                currentUnlock = user[i].amount;
            } else {
                currentUnlock =
                    (user[i].amount * (block.number - user[i].startBlock)) /
                    user[i].delta;
            }
            console.log(currentUnlock);
            accumulatedAmount += currentUnlock - user[i].rewardDebt;
            user[i].rewardDebt = currentUnlock;
        }
        console.log(accumulatedAmount);
        require(IERC20(gton).transfer(to, accumulatedAmount));
        contractRequiredGtonBalance -= accumulatedAmount;

        // rm  bounds if they are over
        for (uint256 i = 0; i < user.length; ) {
            if (block.number >= user[i].startBlock + user[i].delta) {
                userUnlock[msg.sender][i] = userUnlock[msg.sender][
                    userUnlock[msg.sender].length - 1
                ];
                userUnlock[msg.sender].pop();
            } else {
                i++;
            }
        }
    }

    event RevertFlag(bool flag);
    event SetOwner(address oldOwner, address newOwner);
}
