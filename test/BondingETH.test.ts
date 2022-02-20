import { ethers, waffle } from "hardhat"
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"
import { timestampSetter, blockGetter, expandTo18Decimals, expandToDecimals } from "./shared/utils"

import { MockBondStorage } from "../types/MockBondStorage"
import { MockAggregator } from "../types/MockAggregator"
import { MockBondingETH } from "../types/MockBondingETH"
import { MockERC20 } from "../types/MockERC20"
import { MockStaking } from "../types/MockStaking"
import { BigNumber, ContractReceipt } from "ethers"

use(solidity)

describe("BondingETH", function () {
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
    let bonding: MockBondingETH;
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
            ethers.utils.formatBytes32String("7d")) as MockBondingETH;
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
        await gton.mint(bonding.address, expandTo18Decimals(500000))
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
        const type = ethers.utils.formatBytes32String("VC")
        await expect(bonding.connect(alice).mintFor(amount, alice.address, type)).to.be.revertedWith("Ownable: caller is not the owner");
        const tx = await bonding.mintFor(amount, alice.address, type, {value: amount});
        const id = extractTokenId(await tx.wait())
        expect(alice.address).to.eq(await storage.ownerOf(id));
        expect(await bonding.isActiveBond(id)).to.eq(true);
    })

    it("Can mint and claim after the bond period", async () => {
        const amount = expandTo18Decimals(100)
        const tx = await bonding.mint(amount, {value: amount});
        const rc = await tx.wait();
        const id = extractTokenId(rc);
        const data = await bonding.activeBonds(id);
        await storage.approve(bonding.address, id);
        await expect(bonding.claim(id)).to.be.revertedWith("Bonding: Bond is locked to claim now");
        await setTimestamp(data.releaseTimestamp.toNumber())
        await bonding.claim(id);
    })

    it("Cannot claim bond that does not exist", async () => {
        await expect(bonding.claim(0)).to.be.revertedWith("Bonding: Cannot claim inactive bond");
    })

    it("can transfer token and then claim", async () => {
        const amount = expandTo18Decimals(100)
        const tx = await bonding.mint(amount, {value: amount});
        const rc = await tx.wait();
        const id = extractTokenId(rc);
        const data = await bonding.activeBonds(id);
        await storage.transfer(alice.address, id);
        await storage.connect(alice).approve(bonding.address, id);
        await expect(bonding.connect(alice).claim(id)).to.be.revertedWith("Bonding: Bond is locked to claim now");
        await setTimestamp(data.releaseTimestamp.toNumber())
        await bonding.connect(alice).claim(id);
    })

    it("Access private functions check", async () => {

    })

    it("Can transfer funds from contract", async () => {
        // works because of empty contract eth stoarge
        await expect(bonding.connect(alice).transferFunds(alice.address)).to.be.revertedWith("Ownable: caller is not the owner");
        const amount = expandTo18Decimals(100)
        await bonding.mint(amount, {value: amount}) // mint to be sure that balance is not 0
        const balanceBefore = await waffle.provider.getBalance(alice.address);
        await bonding.transferFunds(alice.address); 
        expect(await waffle.provider.getBalance(alice.address)).to.eq(balanceBefore.add(amount))
    })
    const amounts = [
        expandTo18Decimals(1),
        expandTo18Decimals(150),
        expandTo18Decimals(50000),
        expandToDecimals(1, 12),
        expandToDecimals(1, 6),
        expandToDecimals(1, 4) 
        // trouble appears on 2 decimals
    ]
    it("Check that contract gives correct discount with any decimal", async () => {
        const dN = await bonding.discountNominator();
        const dD = await bonding.discountDenominator();
        for(const amount of amounts) {
            const discount = amount.div(dD).mul(dN);
            const amountWithDis = amount.sub(discount)
            const amountWithoutDis = await bonding.amountWithoutDiscount(amountWithDis)
            expect(amountWithoutDis).to.eq(amount)
        }
    })
});
