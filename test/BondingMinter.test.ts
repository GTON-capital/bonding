import { ethers, waffle } from "hardhat"
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"
import { timestampSetter, blockGetter } from "./shared/utils"

import { MockBondStorage } from "../types/MockBondStorage"
import { MockAggregator } from "../types/MockAggregator"
import { MockBondingClaimer } from "../types/MockBondingClaimer"
import { MockBondingMinter } from "../types/MockBondingMinter"

use(solidity)

describe("Bonding", function () {
    const bondLimit = 1000;
    const bondPeriods = {
        month: 2629800,
        quarter: 2629800 * 3
    }
    const [wallet,bob,carol,alice,dev] = waffle.provider.getWallets()

    const setTimestamp = timestampSetter(waffle.provider)
    const getLastTS = blockGetter(waffle.provider, "timestamp")

    let BondClaimer: any
    let BondMinter: any
    let BondStorage: any
    let Aggregator: any

    let storage: MockBondStorage;
    let agg: MockAggregator;
    let minter: MockBondingMinter;
    let claimer: MockBondingClaimer;

    before(async () => {
        BondClaimer = await ethers.getContractFactory("MockBondingClaimer")
        BondMinter = await ethers.getContractFactory("MockBondingMinter")
        BondStorage = await ethers.getContractFactory("MockBondStorage")
        Aggregator = await ethers.getContractFactory("MockAggregator")
    })

    beforeEach(async function () {
        storage = await BondStorage.deploy("BondStorage", "BondS") as MockBondStorage;
        agg = await Aggregator.deploy(6, 2120000) as MockAggregator; // 2.12
        minter = await BondMinter.deploy(bondLimit, bondPeriods.quarter, storage.address, agg.address) as MockBondingMinter;
        await storage.transferOwnership(minter.address)
      })

    it("Checks that mint issues nft token to user", async function () {
        await minter.startBonding();
        const id = (await minter.mint()).value;
        expect(wallet.address).to.eq(await storage.ownerOf(id));
    })

    it("Cannot issue bond without active period and issue of bond ends after period", async () => {
        await expect(minter.mint()).to.be.revertedWith("BondingMinter: Mint is not available in this period");
        await minter.startBonding();
        await minter.mint();
        await setTimestamp((await minter.bondExpiration()).toNumber())
        await expect(minter.mint()).to.be.revertedWith("BondingMinter: Mint is not available in this period");
    })
});
