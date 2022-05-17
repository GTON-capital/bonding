const { ethers } = require("hardhat");
const { waffle } = require("hardhat");
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"
import { timestampSetter, blockGetter, expandTo18Decimals, expandToDecimals, extractTokenId } from "../shared/utils"

import { 
    BondStorage,
    MockAggregator,
    GTONTwapBondingETH,
    MockERC20,
    MockStaking
} from "../../types"

use(solidity)

describe("TwapBondingETH", function () {
    const bondLimit = 1000;
    const time = {
        year: 31557600,
        day: 86400,
        month: 2629800,
        quarter: 2629800 * 3,
        halfMonth: 1209600
    }
    const [wallet, bob, carol, alice, dev] = waffle.provider.getWallets()

    const setTimestamp = timestampSetter(waffle.provider)

    let Bonding: any
    let BondStorage: any
    let Aggregator: any
    let ERC20: any
    let Staking: any

    let storage: BondStorage;
    let gtonAgg: MockAggregator;
    let tokenAgg: MockAggregator;
    let bonding: GTONTwapBondingETH;
    let sgton: MockStaking;
    let gton: MockERC20
    let token: MockERC20

    before(async () => {
        Bonding = await ethers.getContractFactory("GTONTwapBondingETH", wallet)
        BondStorage = await ethers.getContractFactory("BondStorage")
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
            ethers.utils.formatBytes32String("7d")) as GTONTwapBondingETH;
    }

    beforeEach(async function () {
        gton = await ERC20.deploy("Graviton", "GTON");
        sgton = await Staking.deploy(gton.address, "Staking GTON", "sGTON", 2232, time.day)
        token = await ERC20.deploy("Token", "TKN");
        storage = await BondStorage.deploy("BondStorage", "BondS") as BondStorage;
        gtonAgg = await Aggregator.deploy(6, 2120000) as MockAggregator; // 2.12
        tokenAgg = await Aggregator.deploy(6, 2120000) as MockAggregator; // 2.12
        bonding = await deployDefaultBonding()
        await bonding.startBonding();
        await storage.setAdmin(bonding.address)
        await gton.mint(bonding.address, expandTo18Decimals(500000))
    })

    const sampleAmount = expandTo18Decimals(10);


    it("Checks that mint issues nft token to user", async function () {
        const tx = await bonding.mint(sampleAmount, { value: sampleAmount });
        const rc = await tx.wait();
        const id = extractTokenId(rc);
        expect(wallet.address).to.eq(await storage.ownerOf(id));
        expect(await bonding.isActiveBond(id)).to.eq(true);
    })

    it("Cannot issue bond without active period and issue of bond ends after period", async () => {
        expect(await bonding.isBondingActive()).to.eq(true);
        await bonding.mint(sampleAmount, { value: sampleAmount });
        await setTimestamp((await bonding.bondingWindowEndTimestamp()).toNumber())
        await expect(bonding.mint(sampleAmount)).to.be.revertedWith("Bonding: Mint is not available in this period");
        expect(await bonding.isBondingActive()).to.eq(false);
    })

    it("Check that it is impossible to mint with insufficient approve", async () => {
        await expect(bonding.mint(sampleAmount, { value: sampleAmount.sub(1) })).to.be.revertedWith("Bonding: Insufficient amount of ETH");
    })

    it("Can transfer native token from contract", async () => {
        // works because of empty contract eth stoarge
        await expect(bonding.connect(alice).transferNative(alice.address)).to.be.revertedWith("Not owner");
        const amount = expandTo18Decimals(100)
        await bonding.mint(amount, { value: amount }) // mint to be sure that balance is not 0
        const balanceBefore = await waffle.provider.getBalance(alice.address);
        await bonding.transferNative(alice.address);
        expect(await waffle.provider.getBalance(alice.address)).to.eq(balanceBefore.add(amount))
    })

});
