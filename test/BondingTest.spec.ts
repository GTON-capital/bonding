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
    
        this.BigBanger = await ethers.getContractFactory("BoundingClaimer")
        this.relictToken = await ethers.getContractFactory("BoundingMinter")
        this.ERC20Mock = await ethers.getContractFactory("ERC20Mock", this.minter)
    })

});
