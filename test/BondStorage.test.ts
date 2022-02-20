import { ethers, waffle } from "hardhat"
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"

import { MockBondStorage } from "../types/MockBondStorage"
import { BigNumber, BigNumberish, ContractReceipt, Wallet } from "ethers"
import { extractTokenId } from "./shared/utils"
use(solidity)

describe("BondStorage", function () {

    const name = "BondStorage"
    const symbol = "BondNFT"

    const [wallet, bob, carol, alice, dev] = waffle.provider.getWallets()

    let BondStorage: any
    let storage: MockBondStorage

    before(async () => {
        BondStorage = await ethers.getContractFactory("MockBondStorage");
    })

    beforeEach(async () => {
        storage = await BondStorage.deploy(name, symbol)
    })
    const getLastTokenId = async () => {
        return (await storage.tokenCounter()).sub(1)
    }
    it("Initial state values check", async () => {
        expect(await storage.name()).to.eq(name)
        expect(await storage.symbol()).to.eq(symbol)
        expect(await storage.tokenCounter()).to.eq(0)
    })

    it("Mint accessible to owner only", async() => {
        await expect(storage.connect(alice).mint(alice.address)).to.be.revertedWith("Ownable: caller is not the owner");
        await storage.mint(alice.address);
        const id = await getLastTokenId()
        expect(await storage.ownerOf(id)).to.eq(alice.address)
    })

    it("Transfer", async () => {
        await storage.mint(alice.address);
        const id = await getLastTokenId()
        await expect(storage.transfer(alice.address, id)).to.be.revertedWith("BondStorage: You are not the owner");
        await storage.connect(alice).transfer(wallet.address, id);
        expect(await storage.ownerOf(id)).to.eq(wallet.address)
    })
})