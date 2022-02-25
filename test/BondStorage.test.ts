import { ethers, waffle } from "hardhat"
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"

import { BondStorage } from "../types/BondStorage"

use(solidity)

describe("BondStorage", function () {

    const name = "BondStorage"
    const symbol = "BondNFT"

    const [wallet, bob, carol, alice, dev] = waffle.provider.getWallets()

    let BondStorage: any
    let storage: BondStorage

    before(async () => {
        BondStorage = await ethers.getContractFactory("BondStorage");
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

    it("Check mints of user", async () => {
        // mint 2 tokens to alice
        await storage.mint(alice.address); // 0 id
        await storage.mint(alice.address); // 1 id
        expect(await storage.userIdsLength(alice.address)).to.eq(2);
        expect(await storage.userIds(alice.address, 0)).to.eq(0);
        expect(await storage.userIds(alice.address, 1)).to.eq(1);
    })

    it("Check issuedBy", async () => {
        await storage.mint(alice.address); // 0 id
        expect(await storage.issuedBy(0)).to.eq(wallet.address);
    })

    it("Mint accessible to owner only", async() => {
        await expect(storage.connect(alice).mint(alice.address)).to.be.revertedWith("AdminAccess: restricted to admin or owner only");
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