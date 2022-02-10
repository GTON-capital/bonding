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


    let Aggregator:any
    let BondClaimer:any
    let BondMinter:any
    let BondStorage:any

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
        await storage.deployed();
        agg = await Aggregator.deploy(6, 2120000) as MockAggregator; // 2.12
        await agg.deployed();
      })

});
