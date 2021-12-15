import { waffle } from "hardhat"
import { expect } from "./shared/expect"
import { BigNumber, BigNumberish, utils } from 'ethers'

import { boundingFixture } from "./shared/fixtures"

import { Bounding } from "../typechain/Bounding"
import { WETH9 } from "../typechain/WETH9"
import { ERC20 } from "../typechain/ERC20"
import { TestAggregator } from "../typechain/TestAggregator"
import { TestCan } from "~/typechain/TestCan"

import {expandTo18Decimals, TokenData, mineBlocks} from "./shared/utils"

describe("Bounding", () => {
  const [wallet, treasury, other] = waffle.provider.getWallets()

  let loadFixture: ReturnType<typeof waffle.createFixtureLoader>

  before("create fixture loader", async () => {
    loadFixture = waffle.createFixtureLoader([wallet, treasury, other], waffle.provider)
  })

  let weth: WETH9
  let token0: ERC20
  let token1: ERC20
  let gton: ERC20

  let bounding: Bounding

  let token0Agg: TestAggregator
  let token1Agg: TestAggregator
  let gtonAgg: TestAggregator
  let wethAgg: TestAggregator

  let wethCan: TestCan
  let token0Can: TestCan
  let token1Can: TestCan

  let tokens: TokenData[]

  beforeEach("deploy test contracts", async () => {
    ; ({
      weth,
      gton,
      token0,
      token1,
      bounding,
      token0Agg,
      token1Agg,
      gtonAgg,
      wethAgg,
      token1Can,
      token0Can,
      wethCan
    } = await loadFixture(boundingFixture))

    tokens = [
      { can: token0Can, price: token0Agg, minimalAmount: BigNumber.from("10000000000000000") },
      { can: token1Can, price: token1Agg, minimalAmount: BigNumber.from("500000000000000000") },
      { can: wethCan, price: wethAgg, minimalAmount: BigNumber.from("100000000000000") }
    ]
  })

  it("constructor initializes variables", async () => {
    expect(await bounding.owner()).to.eq(wallet.address)
    expect(await bounding.gton()).to.eq(gton.address)
    expect(await bounding.treasury()).to.eq(treasury.address)
    expect(await bounding.revertFlag()).to.eq(false)
  })

  it("transfer ownership", async () => {
    await expect(bounding.connect(other).transferOwnership(wallet.address)).to.be.revertedWith('Bounder: permitted to owner only.')
    await bounding.transferOwnership(other.address)
    expect(await bounding.owner()).to.eq(other.address)
  })

  async function addDiscount({delta, discountMul, discountDiv}: {delta: BigNumber, discountMul: BigNumber, discountDiv: BigNumber}) {
    await bounding.addDiscount(delta, discountMul, discountDiv)
    const last = await bounding.discountsLength();
    const res = await bounding.discounts(last.sub(1));
    expect(res.delta).to.eq(delta)
    expect(res.discountMul).to.eq(discountMul)
    expect(res.discountDiv).to.eq(discountDiv)
  }
  async function checkDiscount(id: number, discount: {
    delta: BigNumber,
    discountMul: BigNumber,
    discountDiv: BigNumber,
  }) {
    const res = await bounding.discounts(id);
    expect(res.delta).to.eq(discount.delta)
    expect(res.discountMul).to.eq(discount.discountMul)
    expect(res.discountDiv).to.eq(discount.discountDiv)
  }

  const discounts = [
    {
      delta: BigNumber.from(6000),
      discountMul: BigNumber.from(70),
      discountDiv: BigNumber.from(2),
    },
    {
      delta: BigNumber.from(100000),
      discountMul: BigNumber.from(120),
      discountDiv: BigNumber.from(12),
    },
    {
      delta: BigNumber.from(15000),
      discountMul: BigNumber.from(50),
      discountDiv: BigNumber.from(90),
    },
  ]
  it("add discount", async () => {
    await expect(bounding.connect(other).addDiscount(1, 12, 1)).to.be.revertedWith('Bounder: permitted to owner only.')
    await addDiscount(discounts[0])
  })

  it("remove discount", async () => {
    await addDiscount(discounts[0])
    await addDiscount(discounts[1])
    await addDiscount(discounts[2])
    expect(await bounding.discountsLength()).to.eq(3);
    await expect(bounding.connect(other).rmDiscount(0)).to.be.revertedWith('Bounder: permitted to owner only.')
    await bounding.rmDiscount(0)

    // expect 3rd element to be swapped in place of 1st
    await checkDiscount(0, discounts[2])
    // expect 3rd element to be deleted
    await expect(bounding.discounts(2)).to.be.reverted
  })

  it("change discount", async () => {
    await addDiscount(discounts[2])
    await expect(bounding.connect(other).changeDiscount(
      0,
      discounts[1].delta,
      discounts[1].discountMul,
      discounts[1].discountDiv)).to.be.revertedWith('Bounder: permitted to owner only.')

    await bounding.changeDiscount(
      0,
      discounts[1].delta,
      discounts[1].discountMul,
      discounts[1].discountDiv)

    await checkDiscount(0, discounts[1])
  })

  it("get token amount with discount", async () => {
    const t0 = discounts[0]
    const t1 = discounts[1]
    expect(await bounding.getTokenAmountWithDiscount(t0.discountMul, t0.discountDiv, token0Agg.address, expandTo18Decimals(10)))
      .to.eq("17500000000000000000")
    expect(await bounding.getTokenAmountWithDiscount(t0.discountMul, t0.discountDiv, token0Agg.address, expandTo18Decimals(5)))
      .to.eq("8750000000000000000")
    expect(await bounding.getTokenAmountWithDiscount(t0.discountMul, t0.discountDiv, token0Agg.address, expandTo18Decimals(30)))
      .to.eq("52500000000000000000")

      expect(await bounding.getTokenAmountWithDiscount(t1.discountMul, t1.discountDiv, token1Agg.address, expandTo18Decimals(10)))
      .to.eq("2540000000000000000")
    expect(await bounding.getTokenAmountWithDiscount(t1.discountMul, t1.discountDiv, token1Agg.address, expandTo18Decimals(5)))
      .to.eq("1270000000000000000")
    expect(await bounding.getTokenAmountWithDiscount(t1.discountMul, t1.discountDiv, token1Agg.address, expandTo18Decimals(30)))
      .to.eq("7620000000000000000")
  })

  async function checkToken(id: BigNumberish, { can, price, minimalAmount }: TokenData) {
    const token = await bounding.allowedTokens(id)
    const tokenAddress = await can.token();
    expect(token.price).to.eq(price.address)
    expect(token.token).to.eq(tokenAddress)
    expect(token.can).to.eq(can.address)
    expect(token.minimalAmount).to.eq(minimalAmount)
  }

  async function addToken({ can, price, minimalAmount }: TokenData) {
    await bounding.addAllowedToken(price.address, can.address, minimalAmount)
    const last = await bounding.tokensLength();
    await checkToken(last.sub(1), {can, price, minimalAmount})
  }

  it("add token", async () => {
    for (const item of tokens) {
      await addToken(item)
    }
  })

  it("remove token", async () => {
    const token = tokens[0]
    await expect(bounding.connect(other)
      .addAllowedToken(token.price.address, token.can.address, token.minimalAmount))
      .to.be.revertedWith("Bounder: permitted to owner only.");
    for (const item of tokens) {
      await addToken(item)
    }
    await expect(bounding.connect(other).rmAllowedToken(0)).to.be.revertedWith("Bounder: permitted to owner only.");
    expect(await bounding.tokensLength()).to.eq(tokens.length);
    await bounding.rmAllowedToken(0)

    // expect 3rd element to be swapped in place of 1st
    await checkToken(0, tokens[2])
    // expect 3rd element to be deleted
    await expect(bounding.allowedTokens(2)).to.be.reverted
  })

  it("change token", async () => {
    const token0 = tokens[0]
    const token1 = tokens[1]
    await addToken(token0)
    const last = await bounding.tokensLength();

    await expect(bounding.connect(other)
      .changeAllowedToken(last.sub(1), token1.price.address, token1.can.address, token1.minimalAmount))
      .to.be.revertedWith("Bounder: permitted to owner only.");

    await bounding.changeAllowedToken(last.sub(1), token1.price.address, token1.can.address, token1.minimalAmount)
    checkToken(last.sub(1), token1)
  })

  it("create bound", async () => {
    const token = tokens[0]
    const dis = discounts[0]
    const wrongDis = discounts[1]
    await addDiscount(dis) // id 0
    await addToken(token) // id 0 

    await expect(bounding.createBound(0, 0, token1.address, expandTo18Decimals(10),dis.discountMul, dis.discountDiv))
    .to.be.revertedWith("Bounding: wrong token address.");
    await expect(bounding.createBound(0, 0, token0.address, expandTo18Decimals(10),wrongDis.discountMul, wrongDis.discountDiv))
    .to.be.revertedWith("Bounding: discound policy has changed.");
    await expect(bounding.createBound(0, 0, token0.address, token.minimalAmount.sub(1), dis.discountMul, dis.discountDiv))
    .to.be.revertedWith("Bounding: amount lower than minimal");
    await expect(bounding.createBound(0, 0, token0.address, token.minimalAmount,dis.discountMul, dis.discountDiv))
      .to.be.reverted;
    await token0.approve(bounding.address, token.minimalAmount);
    await bounding.createBound(0, 0, token0.address, token.minimalAmount, dis.discountMul, dis.discountDiv)
    expect(await token0.balanceOf(treasury.address)).to.be.eq(token.minimalAmount)
    const data = await bounding.userUnlock(wallet.address, 0)
    expect(data.rewardDebt).to.eq(0)    
    expect(data.amount).to.eq("17500000000000000")    
    expect(data.delta).to.eq(dis.delta)
  })

  it("claim bound", async () => {
    const token = tokens[0]
    const dis = discounts[0]
    await addDiscount(dis) // id 0
    await addToken(token) // id 0 

    await gton.transfer(bounding.address, expandTo18Decimals(10000))
    await expect(bounding.claimBound("1000", 0, wallet.address)).to.be.reverted; // throws error out of bounds

    await token0.approve(bounding.address, token.minimalAmount);
    await bounding.createBound(0, 0, token0.address, token.minimalAmount, dis.discountMul, dis.discountDiv)

    const recvAmount = await bounding.getTokenAmountWithDiscount(dis.discountMul, dis.discountDiv, token0Agg.address, token.minimalAmount)
    const maxAmount1 = recvAmount.div(dis.delta)
    await expect(bounding.claimBound(maxAmount1.add(1), 0, wallet.address)).to.be.revertedWith("Bounding: not enough of unlocked token.")
    
    await mineBlocks(waffle.provider, 6000)
    
    const balanceBefore = await gton.balanceOf(wallet.address)
    const maxAmount2 = recvAmount.mul(6000).div(dis.delta)
    await expect(bounding.claimBound(maxAmount2.add(1), 0, wallet.address)).to.be.revertedWith("Bounding: not enough of unlocked token.")
    
    bounding.claimBound(maxAmount2, 0, wallet.address)
    expect(await gton.balanceOf(wallet.address)).to.eq(balanceBefore.add(maxAmount2))
    await expect(bounding.userUnlock(wallet.address, 0)).to.be.reverted;
  })
  async function getRewardOut({discountMul, discountDiv, delta}: {delta: BigNumber, discountMul: BigNumber, discountDiv: BigNumber}, 
      agg: TestAggregator, amount: BigNumber, blockAmount: number) {
    const passedBlocks = (await waffle.provider.getBlock("latest")).number
    const lastBound = await bounding.boundsLength(wallet.address);
    const startBlock = (await bounding.userUnlock(wallet.address,lastBound.sub(1))).startBlock.toNumber()
    const amountRecv = await bounding.getTokenAmountWithDiscount(discountMul, discountDiv, agg.address, amount)
    let a;
    if((blockAmount + passedBlocks - startBlock) >= delta.toNumber()) {
      a = amountRecv
    } else {
      a = amountRecv.mul(blockAmount + passedBlocks - startBlock).div(delta)
    }
    console.log("c");
    console.log(a.toString());
    return a;
  }
  it("claim total bound", async () => {
    const blockAmount = 10000;
    for(const item of discounts) {
      await addDiscount(item)
    }
    for(const token of tokens) {
      await addToken(token)
    }
    await gton.transfer(bounding.address, expandTo18Decimals(10000))

    await token0.approve(bounding.address, tokens[0].minimalAmount);
    await bounding.createBound(1, 0, token0.address, tokens[0].minimalAmount, discounts[1].discountMul, discounts[1].discountDiv)
    const a1 = await getRewardOut(discounts[1], token0Agg, tokens[0].minimalAmount, blockAmount) // it will work if you add 6 to blockAmount

    await token0.approve(bounding.address, tokens[0].minimalAmount);
    await bounding.createBound(0, 0, token0.address, tokens[0].minimalAmount, discounts[0].discountMul, discounts[0].discountDiv)
    const a2 = await getRewardOut(discounts[0], token0Agg, tokens[0].minimalAmount, blockAmount)

    await token1.approve(bounding.address, tokens[1].minimalAmount);
    await bounding.createBound(0, 1, token1.address, tokens[1].minimalAmount, discounts[0].discountMul, discounts[0].discountDiv)
    const a3 = await getRewardOut(discounts[0], token1Agg, tokens[1].minimalAmount, blockAmount)

    await token1.approve(bounding.address, tokens[1].minimalAmount);
    await bounding.createBound(1, 1, token1.address, tokens[1].minimalAmount, discounts[1].discountMul, discounts[1].discountDiv)
    const a4 = await getRewardOut(discounts[1], token1Agg, tokens[1].minimalAmount, blockAmount)

    await mineBlocks(waffle.provider, blockAmount - 1) // to count upcoming txn with claim
    
    await bounding.claimBoundTotal(other.address);
    const total = a1.add(a2).add(a3).add(a4)
    expect(await gton.balanceOf(other.address)).to.eq(total)
  })

})
