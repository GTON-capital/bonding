import { ethers, waffle } from "hardhat"
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"
import { timestampSetter, blockGetter, expandTo18Decimals } from "./shared/utils"

import { MockBondStorage } from "../types/MockBondStorage"
import { MockAggregator } from "../types/MockAggregator"
import { MockBonding } from "../types/MockBonding"
import { MockERC20 } from "../types/MockERC20"
import { MockStaking } from "../types/MockStaking"

use(solidity)

describe("Bonding", function () {
    const bondLimit = 1000;
    const time = {
        day: 86400,
        month: 2629800,
        quarter: 2629800 * 3,
        halfMonth: 1209600
    }
    const [wallet,bob,carol,alice,dev] = waffle.provider.getWallets()

    const setTimestamp = timestampSetter(waffle.provider)
    const getLastTS = blockGetter(waffle.provider, "timestamp")

    let Bonding: any
    let BondStorage: any
    let Aggregator: any
    let ERC20: any
    let Staking: any

    let storage: MockBondStorage;
    let gtonAgg: MockAggregator;
    let tokenAgg: MockAggregator;
    let bonding: MockBonding;
    let sgton: MockStaking;
    let gton: MockERC20
    let token: MockERC20

    before(async () => {
        Bonding = await ethers.getContractFactory("MockBondingETH")
        BondStorage = await ethers.getContractFactory("MockBondStorage")
        Aggregator = await ethers.getContractFactory("MockAggregator")
        ERC20 = await ethers.getContractFactory("MockERC20")
        Staking = await ethers.getContractFactory("MockStaking")
    })
    beforeEach(async function () {
        gton = await ERC20.deploy("Graviton", "GTON");
        sgton = await Staking.deploy(gton.address, "Staking GTON", "sGTON", 2232, time.day)
        token = await ERC20.deploy("Token", "TKN");
        storage = await BondStorage.deploy("BondStorage", "BondS") as MockBondStorage;
        gtonAgg = await Aggregator.deploy(6, 2120000) as MockAggregator; // 2.12
        tokenAgg = await Aggregator.deploy(6, 2120000) as MockAggregator; // 2.12
        bonding = await Bonding.deploy(
            bondLimit, 
            time.quarter, 
            time.halfMonth, 
            storage.address, 
            tokenAgg.address, 
            gtonAgg.address, 
            token.address, 
            gton.address,
            sgton.address) as MockBonding;
        await storage.transferOwnership(bonding.address)
      })

    const sampleAmount = expandTo18Decimals(10);
    it("Checks that mint issues nft token to user", async function () {
        await bonding.startBonding();
        const id = (await bonding.mint(sampleAmount)).value;
        expect(wallet.address).to.eq(await storage.ownerOf(id));
    })

    it("Cannot issue bond without active period and issue of bond ends after period", async () => {
        await expect(bonding.mint(sampleAmount)).to.be.revertedWith("BondingMinter: Mint is not available in this period");
        await bonding.startBonding();
        await bonding.mint(sampleAmount);
        await setTimestamp((await bonding.bondExpiration()).toNumber())
        await expect(bonding.mint(sampleAmount)).to.be.revertedWith("BondingMinter: Mint is not available in this period");
    })

    it("", async () => {
        
    })

    it("", async () => {

    })

    it("", async () => {

    })

    it("", async () => {

    })

    it("", async () => {

    })
});
