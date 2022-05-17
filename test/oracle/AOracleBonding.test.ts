const { ethers } = require("hardhat");
const { waffle } = require("hardhat");
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"
import { timestampSetter, blockGetter, expandTo18Decimals, expandToDecimals, extractTokenId } from "../shared/utils"

import { 
    BondStorage,
    MockAggregator,
    MockAOracleBonding,
    MockERC20,
    MockStaking
} from "../../types"

import { BigNumber, BigNumberish, Wallet } from "ethers"

use(solidity)

describe("AOracleBonding", function () {
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
    let bonding: MockAOracleBonding;
    let sgton: MockStaking;
    let gton: MockERC20
    let token: MockERC20

    before(async () => {
        Bonding = await ethers.getContractFactory("MockAOracleBonding", wallet)
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
            ethers.utils.formatBytes32String("7d")) as MockAOracleBonding;
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
        await token.mint(wallet.address, expandTo18Decimals(500000))
        await token.mint(alice.address, expandTo18Decimals(5000))
    })

    it("Cannot activate active bonding and check access", async () => {
        await expect(bonding.connect(alice).startBonding()).to.be.revertedWith("Not owner");
        await expect(bonding.startBonding()).to.be.revertedWith("Bonding: Bonding is already active");
    })

    it("Can mint and claim after the bond period", async () => {
        const amount = expandTo18Decimals(100)
        const tx = await bonding.mint(amount);
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

    it("Can transfer nft token and then claim", async () => {
        const amount = expandTo18Decimals(100)
        const tx = await bonding.mint(amount);
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
        await expect(bonding.connect(alice).setGtonAggregator(tokenAgg.address)).to.be.revertedWith("Not owner")
        await bonding.setGtonAggregator(tokenAgg.address)
        expect(await bonding.gtonAggregator()).to.eq(tokenAgg.address);

        await expect(bonding.connect(alice).setTokenAggregator(gtonAgg.address)).to.be.revertedWith("Not owner")
        await bonding.setTokenAggregator(gtonAgg.address)
        expect(await bonding.tokenAggregator()).to.eq(gtonAgg.address);

        const nominator = 1000
        await expect(bonding.connect(alice).setDiscountNominator(nominator)).to.be.revertedWith("Not owner")
        await bonding.setDiscountNominator(nominator)
        expect(await bonding.discountNominator()).to.eq(nominator);

        const activePeriod = 199002234
        await expect(bonding.connect(alice).setBondActivePeriod(activePeriod)).to.be.revertedWith("Not owner")
        await bonding.setBondActivePeriod(activePeriod)
        expect(await bonding.bondActivePeriod()).to.eq(activePeriod);

        const bondToClaimPeriod = 199002234
        await expect(bonding.connect(alice).setBondToClaimPeriod(bondToClaimPeriod)).to.be.revertedWith("Not owner")
        await bonding.setBondToClaimPeriod(bondToClaimPeriod)
        expect(await bonding.bondToClaimPeriod()).to.eq(bondToClaimPeriod);

        const bondLimit = 199002234
        await expect(bonding.connect(alice).setBondLimit(bondLimit)).to.be.revertedWith("Not owner")
        await bonding.setBondLimit(bondLimit)
        expect(await bonding.bondLimit()).to.eq(bondLimit);

    })

    it("Can transfer funds from contract", async () => {
        // works because of empty contract eth stoarge
        await expect(bonding.connect(alice).transferToken(token.address, alice.address)).to.be.revertedWith("Not owner");
        const amount = expandTo18Decimals(100)
        await token.transfer(bonding.address, amount)
        const balanceBefore = await token.balanceOf(alice.address);
        await bonding.transferToken(token.address, alice.address);
        expect(await token.balanceOf(alice.address)).to.eq(balanceBefore.add(amount))
    })

    async function mintForClaim(user: Wallet, amount: BigNumberish): Promise<BigNumber> {
        const tx = await bonding.connect(user).mint(amount)
        const rc = await tx.wait();
        const id = extractTokenId(rc);
        const unlockTS = (await bonding.activeBonds(id)).releaseTimestamp
        await setTimestamp(unlockTS.toNumber());
        return id;
    }
    describe("Decimal approximation check", async () => {

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
            for (const amount of amounts) {
                const discount = amount.div(dD).mul(dN);
                const amountWithDis = amount.sub(discount)
                const amountWithoutDis = await bonding.amountWithoutDiscount(amountWithDis)
                expect(amountWithoutDis).to.eq(amount)
            }
        })
        const prices = [
            {
                tokenPrice: 151423,
                tokenDecimals: 5,
                gtonPrice: 653912,
                gtonDecimals: 4
            },
            {
                tokenPrice: 22423,
                tokenDecimals: 3,
                gtonPrice: 63912,
                gtonDecimals: 4
            },
            {
                tokenPrice: 21423,
                tokenDecimals: 4,
                gtonPrice: 21617,
                gtonDecimals: 4
            },
        ]

        async function updatePrice(agg: MockAggregator, price: number, decimals: number) {
            await agg.updatePriceAndDecimals(price, decimals)
        }

        it("Check price and decimals calculations", async () => {
            for (const amount of amounts) {
                for (const { tokenPrice, tokenDecimals, gtonPrice, gtonDecimals } of prices) {
                    await updatePrice(tokenAgg, tokenPrice, tokenDecimals);
                    await updatePrice(gtonAgg, gtonPrice, gtonDecimals);
                    const amountOut = amount.mul(tokenPrice).mul(gtonDecimals).div(tokenDecimals).div(gtonPrice)
                    expect(await bonding.bondAmountOut(amount)).to.eq(amountOut);
                }
            }
        })

        it("Claim releases sgton with staking earned amount", async () => {
            const amount = expandToDecimals(1, 12)
            const id = await mintForClaim(alice, amount)
            await storage.connect(alice).approve(bonding.address, id);
            await bonding.connect(alice).claim(id)
            const stakingPeriod = await bonding.bondToClaimPeriod();
            const aprN = await sgton.aprBasisPoints();
            const aprD = await sgton.aprDenominator();
            const amountWithoutDis = await bonding.amountWithoutDiscount(amount);
            const gtonOut = await bonding.bondAmountOut(amountWithoutDis);
            const yearEarn = gtonOut.mul(aprN).div(aprD);
            const expectedSgton = yearEarn.mul(stakingPeriod).div(time.year)
            expect(await sgton.balanceOf(alice.address)).to.eq(expectedSgton.add(gtonOut));
        })
    })

    describe("Claim", async () => {
        const amount = expandToDecimals(1, 6)
        let id: BigNumber

        beforeEach(async () => {
            id = await mintForClaim(alice, amount)
        })

        it("Claim receives approved nft", async () => {
            await expect(bonding.connect(alice).claim(id)).to.be.revertedWith("ERC721: transfer caller is not owner nor approved")
            await storage.connect(alice).approve(bonding.address, id);
            await bonding.connect(alice).claim(id)
            expect(await storage.ownerOf(id)).to.eq(bonding.address);
        })

        it("Cannot claim bond twice", async () => {
            await storage.connect(alice).approve(bonding.address, id);
            await bonding.connect(alice).claim(id)
            await expect(bonding.connect(alice).claim(id)).to.be.revertedWith("Bonding: Cannot claim inactive bond");
        })

    })

});
