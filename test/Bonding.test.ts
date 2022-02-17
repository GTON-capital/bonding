import { ethers, waffle } from "hardhat"
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"
import { timestampSetter, blockGetter, expandTo18Decimals } from "./shared/utils"

import { MockBondStorage } from "../types/MockBondStorage"
import { MockAggregator } from "../types/MockAggregator"
import { MockBonding } from "../types/MockBonding"
import { MockERC20 } from "../types/MockERC20"
import { MockStaking } from "../types/MockStaking"
import { BigNumber, ContractReceipt } from "ethers"

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
        Bonding = await ethers.getContractFactory("MockBondingETH", wallet)
        BondStorage = await ethers.getContractFactory("MockBondStorage")
        Aggregator = await ethers.getContractFactory("MockAggregator")
        ERC20 = await ethers.getContractFactory("MockERC20")
        Staking = await ethers.getContractFactory("MockStaking")
    })

    async function deployDefaultBonding() {
        return await Bonding.deploy(
            bondLimit, 
            time.quarter, 
            time.halfMonth, 
            2500, // discount
            storage.address, 
            tokenAgg.address, 
            gtonAgg.address, 
            token.address, 
            gton.address,
            sgton.address,
            "7d") as MockBonding;
    } 

    beforeEach(async function () {
        gton = await ERC20.deploy("Graviton", "GTON");
        sgton = await Staking.deploy(gton.address, "Staking GTON", "sGTON", 2232, time.day)
        token = await ERC20.deploy("Token", "TKN");
        storage = await BondStorage.deploy("BondStorage", "BondS") as MockBondStorage;
        gtonAgg = await Aggregator.deploy(6, 2120000) as MockAggregator; // 2.12
        tokenAgg = await Aggregator.deploy(6, 2120000) as MockAggregator; // 2.12
        bonding = await deployDefaultBonding()
        await bonding.startBonding();
        await storage.transferOwnership(bonding.address)
      })
    
    const sampleAmount = expandTo18Decimals(10);

    function extractTokenId(receipt: ContractReceipt): BigNumber {
        const event = receipt.events.find(event => event.event === 'Mint');
        const [id] = event.args;
        return id;
    }

    it("Checks that mint issues nft token to user", async function () {
        const tx = await bonding.mint(sampleAmount, {value: sampleAmount});
        const rc = await tx.wait();
        const id = extractTokenId(rc);
        expect(wallet.address).to.eq(await storage.ownerOf(id));
        expect(await bonding.isActiveBond(id)).to.eq(true);
    })

    it("Cannot issue bond without active period and issue of bond ends after period", async () => {
        expect(await bonding.isBondingActive()).to.eq(true);
        await bonding.mint(sampleAmount, {value: sampleAmount});
        await setTimestamp((await bonding.bondExpiration()).toNumber())
        await expect(bonding.mint(sampleAmount)).to.be.revertedWith("Bonding: Mint is not available in this period");
        expect(await bonding.isBondingActive()).to.eq(false);
    })

    it("check that cannot mint with insufficient approve", async () => {
        await expect(bonding.mint(sampleAmount, {value: sampleAmount.sub(1)})).to.be.revertedWith("Bonding: Insufficient amount of ETH");
    })

    it("cannot activate active bonding and check access", async () => {
        await expect(bonding.connect(alice).startBonding()).to.be.revertedWith("Ownable: caller is not the owner");
        await expect(bonding.startBonding()).to.be.revertedWith("Bonding: Bonding is already active");
    })

    it("owner can mint for anyone", async () => {
        const amount = expandTo18Decimals(150);
        await expect(bonding.connect(alice).mintFor(amount, alice.address, "VC")).to.be.revertedWith("Ownable: caller is not the owner");
        const tx = await bonding.mintFor(amount, alice.address, "VC", {value: amount});
        const id = extractTokenId(await tx.wait())
        expect(alice.address).to.eq(await storage.ownerOf(id));
        expect(await bonding.isActiveBond(id)).to.eq(true);
    })

    it("Can mint and claim after the bond period", async () => {

    })
    
    it("can transfer token and then claim", async () => {

    })

    it("", async () => {

    })
});
