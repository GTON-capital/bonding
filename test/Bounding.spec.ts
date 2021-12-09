import { waffle } from "hardhat"
import { expect } from "./shared/expect"
import { BigNumber, utils } from 'ethers'

import { boundingFixture } from "./shared/fixtures"

import { Bounding } from "../typechain/Bounding"
import { WETH9 } from "../typechain/WETH9"
import { ERC20 } from "../typechain/ERC20"
import { TestAggregator } from "../typechain/TestAggregator"


describe("Bounding", () => {
  const [wallet, other, nebula] = waffle.provider.getWallets()

  let loadFixture: ReturnType<typeof waffle.createFixtureLoader>

  before("create fixture loader", async () => {
    loadFixture = waffle.createFixtureLoader([wallet, other, nebula], waffle.provider)
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
    expect(await bounding.gton()).to.eq(gton.address)
    expect(await bounding.revertFlag()).to.eq(false)
  })

  it("can creation", async () => {
    const farmId: BigNumber = await setupFarm(farm, 100, lpToken.address)
    // check revert modifier
    await candy.toggleRevert()
    await expect(candy.createCan(farmId, farm.address, router.address, lpToken.address, token0.address, relict.address, 0)).to.be.revertedWith('CandyShop: Option is closed to use')
    await candy.toggleRevert()
    // check ownership
    await expect(candy.connect(other).createCan(farmId, farm.address, router.address, lpToken.address, token0.address, relict.address, 0)).to.be.revertedWith('CandyShop: permitted to owner')
    
    await candy.createCan(farmId, farm.address, router.address, lpToken.address, token0.address, relict.address, 0)
    // check for correct enpacked address
    const key = utils.solidityPack(["uint","address","address","address","address",], [farmId, farm.address, lpToken.address, token0.address, relict.address])
    const canAddress = await candy.allCans((await candy.canLength()).sub(1))
    const canKeyAddress = await candy.canContracts(key)
    expect(canAddress).to.eq(canKeyAddress)
    // check for already existing can
    await expect(candy.createCan(farmId, farm.address, router.address, lpToken.address, token0.address, relict.address, 0)).to.be.revertedWith(
      "CandyShop: Can exists"
    )
  })

  it("transfer ownership", async () => {
    await expect(candy.connect(other).transferOwnership(wallet.address)).to.be.revertedWith('CandyShop: permitted to owner')
    await candy.transferOwnership(other.address)
    expect(await candy.owner()).to.eq(other.address)
  })
})
