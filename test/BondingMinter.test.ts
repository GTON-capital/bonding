import { ethers, waffle } from "hardhat"
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"
import { MockBondStorage } from "../types/MockBondStorage"
import { MockAggregator } from "../types/MockAggregator"
import { MockBondingClaimer } from "../types/MockBondingClaimer"
import { MockBondingMinter } from "../types/MockBondingMinter"

use(solidity)

describe("Bonding", async function () {
    const bondLimit = 1000;
    const bondPeriods = {
        month: 2629800,
        quarter: 2629800 * 3
    }
    const [wallet,bob,carol,alice,dev] = await ethers.getSigners()
    
    const BondClaimer = await ethers.getContractFactory("MockBondingClaimer")
    const BondMinter = await ethers.getContractFactory("MockBondingMinter")
    const BondStorage = await ethers.getContractFactory("MockBondStorage")
    const Aggregator = await ethers.getContractFactory("MockAggregator")

    let storage: MockBondStorage;
    let agg: MockAggregator;
    let minter: MockBondingMinter;
    let claimer: MockBondingClaimer;

    beforeEach(async function () {
        storage = await BondStorage.deploy("BondStorage", "BondS") as MockBondStorage;
        await storage.deployed();
        agg = await Aggregator.deploy(6, 2120000) as MockAggregator; // 2.12
        await agg.deployed();
        console.log('afs')
      })

      it("Checks that mint issues nft token to user", async function () {
        minter = await BondMinter.deploy(bondLimit, bondPeriods.quarter, this.storage.address, this.agg.address) as MockBondingMinter;
        await storage.transferOwnership(minter.address)
        await minter.startBonding();
        
        const id = (await minter.mint()).value;
        
        expect(wallet).to.eq(await storage.ownerOf(id));
    })
});
