import { ethers, waffle } from "hardhat"
import { expect, use } from "chai"
import { solidity } from "ethereum-waffle"

use(solidity)

describe("Bonding", function () {

    before(async function () {
        this.signers = await ethers.getSigners()
        this.alice = this.signers[0]
        this.bob = this.signers[1]
        this.carol = this.signers[2]
        this.dev = this.signers[3]
        this.minter = this.signers[4]
    
        this.BondClaimer = await ethers.getContractFactory("MockBoundingClaimer")
        this.BondMinter = await ethers.getContractFactory("MockBoundingMinter")
        this.BondStorage = await ethers.getContractFactory("MockBoundStorage")
    })

    beforeEach(async function () {
        this.storage = await this.BondStorage.deploy("BondStorage", "BondS")
        await this.storage.deployed()
      })

    it("Checks that mint issues nft token connected to user", async () => {
        this.minter = await this.
    })

});
