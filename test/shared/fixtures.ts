import { ethers } from "hardhat"
import { BigNumber, Contract } from "ethers"
import { Fixture } from "ethereum-waffle"

import { Bounding } from "../../typechain/Bounding"
import { WETH9 } from "../../typechain/WETH9"
import { ERC20 } from "../../typechain/ERC20"
import { TestAggregator } from "../../typechain/TestAggregator"

interface TokensFixture {
    weth: WETH9,
    gton: ERC20
    token0: ERC20,
    token1: ERC20
}

async function tokensFixture(): Promise<TokensFixture> {
    const factory = await ethers.getContractFactory("ERC20");
    const factoryWeth = await ethers.getContractFactory("WETH9");
    const gton = (await factory.deploy(BigNumber.from(2).pow(255))) as ERC20
    const token0 = (await factory.deploy(BigNumber.from(2).pow(255))) as ERC20
    const token1 = (await factory.deploy(BigNumber.from(2).pow(255))) as ERC20
    const weth = (await factoryWeth.deploy()) as WETH9

    return { weth, gton, token0, token1 }
}

interface Boundingfixture extends TokensFixture {
    bounding: Bounding
    token0Agg: TestAggregator
    gtonAgg: TestAggregator
    wethAgg: TestAggregator
}

export const boundingFixture: Fixture<Boundingfixture> = async function ([
    wallet, treasury
]): Promise<Boundingfixture> {
    const { weth, token0, token1, gton } = await tokensFixture()
    const aggFactory = await ethers.getContractFactory("TestAggregator");
    const token0Agg = (await aggFactory.deploy(await token0.decimals(), 1)) as TestAggregator
    const gtonAgg = (await aggFactory.deploy(8, 1000000000)) as TestAggregator
    const wethAgg = (await aggFactory.deploy(8, 1000000000)) as TestAggregator
    const bounfingF = await ethers.getContractFactory("Bounding")
    const bounding = (await bounfingF.deploy(gton.address, treasury.address)) as Bounding
    return {
        weth,
        token0,
        token1,
        gton,
        token0Agg,
        wethAgg,
        bounding,
        gtonAgg
    }
}

