
const hre = require("hardhat")
import { 
  ethers,
} from "hardhat"
import { 
  WhitelistWithNFT,
} from "../types"

async function main() {
  await deployAndVerify()
  await addCollection()
}

let contractName = "WhitelistWithNFT"
let nftRinkeby = "0x834eB4A15bA4671ead8B67F46161E864F27C892A"
let nftRopsten = "0x834eb4a15ba4671ead8b67f46161e864f27c892a"
let whitelistRinkeby = "0xf852f018aE42AcEe92B3df1de36cF2CD0a8568f4"
let whitelistRopsten = "0x37655e023A2991e76a8F974AE922e1a34Af36f0f"
let collectionToAdd = nftRinkeby
let contract = whitelistRinkeby

async function deployAndVerify() { 

  console.log("Deploying on network: " + hre.network.name)
  const factory = await ethers.getContractFactory(contractName)
  const contract = await factory.deploy()
  await contract.deployed()

  console.log("Contract deployed to:", contract.address)

  await delay(20000)
  await verify(contract.address)
}

async function verify(address: string) {
  console.log(hre.network.name)
  await hre.run("verify:verify", {
    address: address,
    // network: hre.network.name,
    constructorArguments: [
    ]
  })
}

async function addCollection() {
  try {
    let contract = await getContract() as WhitelistWithNFT
    let request = await contract.addCollection(collectionToAdd)
    console.log("Collection added: " + request.hash)
  } catch (e) {
    console.log(e)
  }
} 

async function getContract() {
  let Bonding = await ethers.getContractFactory(contractName)
  return Bonding.attach(
    contract
  )
}

async function delay(ms: number) {
  return new Promise(resolve => setTimeout(resolve, ms))
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error)
    process.exit(1)
  })
