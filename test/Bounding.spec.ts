import { waffle } from "hardhat"
import { expect } from "./shared/expect"
import { BigNumber, utils } from 'ethers'

import { boundingFixture } from "./shared/fixtures"

import { Bounding } from "../typechain/Bounding"
import { WETH9 } from "../typechain/WETH9"
import { ERC20 } from "../typechain/ERC20"
import { TestAggregator } from "../typechain/TestAggregator"


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
  let gtonAgg: TestAggregator
  let wethAgg: TestAggregator

  beforeEach("deploy test contracts", async () => {
    ; ({
      weth,
      gton,
      token0,
      token1,
      bounding,
      token0Agg,
      gtonAgg,
      wethAgg
    } = await loadFixture(boundingFixture))
  })

  async function setupBounding() {

  }

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

  async function addDiscount(delta: BigNumber, mul: BigNumber, div: BigNumber, min: BigNumber) {
    await bounding.addDiscount(delta, mul, div, min)
    const last = await bounding.discountsLength();
    const res = await bounding.discounts(last.sub(1));
    expect(res.delta).to.eq(delta)
    expect(res.discountMul).to.eq(mul)
    expect(res.discountDiv).to.eq(div)
    expect(res.minimalAmount).to.eq(min)
  }
  async function checkDiscount(id: number, discount: {
    delta: BigNumber,
    discountMul: BigNumber,
    discountDiv: BigNumber,
    minimalAmount: BigNumber
  }) {
    const res = await bounding.discounts(id);
    expect(res.delta).to.eq(discount.delta)
    expect(res.discountMul).to.eq(discount.discountMul)
    expect(res.discountDiv).to.eq(discount.discountDiv)
    expect(res.minimalAmount).to.eq(discount.minimalAmount)
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
    const min = BigNumber.from(100)
    await expect(bounding.connect(other).addDiscount(1, 12, 1, 100)).to.be.revertedWith('Bounder: permitted to owner only.')
    await addDiscount(delta, mul, div, min)
  })

  it("remove discount", async () => {
    await addDiscount(discounts[0].delta, discounts[0].discountMul, discounts[0].discountDiv, discounts[0].minimalAmount)
    await addDiscount(discounts[1].delta, discounts[1].discountMul, discounts[1].discountDiv, discounts[1].minimalAmount)
    await addDiscount(discounts[2].delta, discounts[2].discountMul, discounts[2].discountDiv, discounts[2].minimalAmount)
    expect(await bounding.discountsLength()).to.eq(3);
    await expect(bounding.connect(other).rmDiscount(0)).to.be.revertedWith('Bounder: permitted to owner only.')
    await bounding.rmDiscount(0)

    // expect 3rd element to be swapped in place of 1st
    await checkDiscount(0, discounts[2])
    // expect 3rd element to be deleted
    await expect(bounding.discounts(2)).to.be.reverted
  })

  it("change discount", async () => {
    await addDiscount(discounts[2].delta, discounts[2].discountMul, discounts[2].discountDiv, discounts[2].minimalAmount)
    await expect(bounding.connect(other).changeDiscount(
      0,
      discounts[1].delta,
      discounts[1].discountMul,
      discounts[1].discountDiv,
      discounts[1].minimalAmount)).to.be.revertedWith('Bounder: permitted to owner only.')

    await bounding.changeDiscount(
      0,
      discounts[1].delta,
      discounts[1].discountMul,
      discounts[1].discountDiv,
      discounts[1].minimalAmount)

    await checkDiscount(0, discounts[1])
  })

  async function addToken(token: {canAddress: string, priceAgg: string}) {
    await bounding.addAllowedToken(delta, mul, div, min)
    const last = await bounding.discountsLength();
    const res = await bounding.discounts(last.sub(1));
    expect(res.delta).to.eq(delta)
    expect(res.discountMul).to.eq(mul)
    expect(res.discountDiv).to.eq(div)
    expect(res.minimalAmount).to.eq(min)
  }


  it("add token", async () => {

  })

  it("remove token", async () => {

  })

  it("change token", async () => {
    await addDiscount(discounts[2].delta, discounts[2].discountMul, discounts[2].discountDiv, discounts[2].minimalAmount)
    await expect(bounding.connect(other).changeDiscount(
      0,
      discounts[1].delta,
      discounts[1].discountMul,
      discounts[1].discountDiv,
      discounts[1].minimalAmount)).to.be.revertedWith('Bounder: permitted to owner only.')

    await bounding.changeDiscount(
      0,
      discounts[1].delta,
      discounts[1].discountMul,
      discounts[1].discountDiv,
      discounts[1].minimalAmount)

    await checkToken(0, discounts[1])
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
