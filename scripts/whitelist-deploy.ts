
const hre = require("hardhat")
const Big = require('big.js')
import { 
  ethers,
} from "hardhat"
import { 
  WhitelistWithNFT,
} from "../types"

async function main() {
  await deployAndVerify()
}

let contractName = "WhitelistWithNFT"

let whitelistRinkeby = "0xf852f018aE42AcEe92B3df1de36cF2CD0a8568f4"
let whitelistRopsten = "0x37655e023A2991e76a8F974AE922e1a34Af36f0f"

let memorableNftRinkeby = "0x834eB4A15bA4671ead8B67F46161E864F27C892A"
let lobsRinkeby = "0x37722f3729986E523E6bF8Abc9BAb37f40Ac2712"

let memorableNftRopsten = "0x834eb4a15ba4671ead8b67f46161e864f27c892a"
let lobsRopsten = "0x81fb974d856e8ceeffab5fb1656d2694f872d571"

let megaTokenRopsten = "0xbc10a04b76a5cd6bf2908e1237fb2d557482cf48"

let nftsRopsten = [
  memorableNftRopsten,
  lobsRopsten
]

let tokensRopsten = [
  megaTokenRopsten
]

let initialNfts = nftsRopsten
let initialNftAllocations = [
  Big(1000).mul(1e18).toFixed(),
  Big(5000).mul(1e18).toFixed(),
]

let initialTokens = tokensRopsten
let initialTokenAllocations = [
  Big(6666).mul(1e18).toFixed(),
]
let initialTokenThresholds = [
  Big(1000).mul(1e18).toFixed(),
]

let collectionToAdd = lobsRopsten

let contract = whitelistRopsten

async function deployAndVerify() { 

  console.log("Deploying on network: " + hre.network.name)
  const factory = await ethers.getContractFactory(contractName)
  const contract = await factory.deploy(
    initialNfts,
    initialNftAllocations,
    initialTokens,
    initialTokenAllocations,
    initialTokenThresholds
  )
  console.log("Contract deploying to:", contract.address)

  console.log("Waiting for deploy")
  await contract.deployed()
  console.log("Deployed")

  await delay(20000)
  await hre.run("verify:verify", {
    address: contract.address,
    constructorArguments: [
      initialNfts,
      initialNftAllocations,
      initialTokens,
      initialTokenAllocations,
      initialTokenThresholds
    ]
  })
}

async function addCollection() {
  try {
    let contract = await getContract() as WhitelistWithNFT
    let allocation = Big(1000).mul(1e18)
    let request = await contract.addCollection(collectionToAdd, allocation)
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
