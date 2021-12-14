import { waffle } from "hardhat"
import { expect } from "./shared/expect"
import { BigNumber, BigNumberish, utils } from 'ethers'

import { boundingFixture } from "./shared/fixtures"

import { Bounding } from "../typechain/Bounding"
import { WETH9 } from "../typechain/WETH9"
import { ERC20 } from "../typechain/ERC20"
import { TestAggregator } from "../typechain/TestAggregator"
import { TestCan } from "~/typechain/TestCan"


interface TokenData {
  can: TestCan, 
  price: TestAggregator, 
  minimalAmount: BigNumberish
}

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

  async function addDiscount(delta: BigNumber, mul: BigNumber, div: BigNumber) {
    await bounding.addDiscount(delta, mul, div)
    const last = await bounding.discountsLength();
    const res = await bounding.discounts(last.sub(1));
    expect(res.delta).to.eq(delta)
    expect(res.discountMul).to.eq(mul)
    expect(res.discountDiv).to.eq(div)
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
      delta: BigNumber.from(50),
      discountMul: BigNumber.from(70),
      discountDiv: BigNumber.from(2),
      minimalAmount: BigNumber.from(120000000000000)
    },
    {
      delta: BigNumber.from(100),
      discountMul: BigNumber.from(120),
      discountDiv: BigNumber.from(12),
      minimalAmount: BigNumber.from(120000000000000)
    },
    {
      delta: BigNumber.from(150),
      discountMul: BigNumber.from(50),
      discountDiv: BigNumber.from(90),
      minimalAmount: BigNumber.from(120000000000000)
    },
  ]
  it("add discount", async () => {
    const delta = BigNumber.from(1)
    const mul = BigNumber.from(12)
    const div = BigNumber.from(1)
    await expect(bounding.connect(other).addDiscount(1, 12, 1)).to.be.revertedWith('Bounder: permitted to owner only.')
    await addDiscount(delta, mul, div)
  })

  it("remove discount", async () => {
    await addDiscount(discounts[0].delta, discounts[0].discountMul, discounts[0].discountDiv)
    await addDiscount(discounts[1].delta, discounts[1].discountMul, discounts[1].discountDiv)
    await addDiscount(discounts[2].delta, discounts[2].discountMul, discounts[2].discountDiv)
    expect(await bounding.discountsLength()).to.eq(3);
    await expect(bounding.connect(other).rmDiscount(0)).to.be.revertedWith('Bounder: permitted to owner only.')
    await bounding.rmDiscount(0)

    // expect 3rd element to be swapped in place of 1st
    await checkDiscount(0, discounts[2])
    // expect 3rd element to be deleted
    await expect(bounding.discounts(2)).to.be.reverted
  })

  it("change discount", async () => {
    await addDiscount(discounts[2].delta, discounts[2].discountMul, discounts[2].discountDiv)
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

  it("get token amount with discount", async () => {

  })

  it("create bound", async () => {

  })


  it("claim bound", async () => {

  })

  it("claim total bound", async () => {

  })

})
