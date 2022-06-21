
const hre = require("hardhat")
import { run, ethers } from "hardhat"
import { 
  GTONTwapBondingETH,
  TwapOracle
} from "../types"

async function main() {
  await deployAndTwapOracle()
}

let rinkebyBondingWeek = ""
let rinkebyBonding90days = ""
let contract = rinkebyBondingWeek

let configWeek = {
  bondLimit: 250,
  bondActivePeriod: 604800, // 604800 - week
  bondToClaimPeriod: 3600,
  discountBasisPoints: 2500,
  bondStorageAddress: "0x9E8bcf8360Da63551Af0341A67538c918ba81007",
  tokenPriceFeedAddress: "0xe9cF2EEDd15a024CEa69B29F6038A02aD468529B",
  gtonPriceFeedAddress: "0xc28c12150CB0f79a03f627c07C54725F6c397608",
  tokenAddress: "0xd0011de099e514c2094a510dd0109f91bf8791fa",
  gtonAddress: "0xc4d0a76ba5909c8e764b67acf7360f843fbacb2d",
  stakedGtonAddress: "0x314650ac2876c6B6f354499362Df8B4DC95E4750",
  bondTypeString: "7d"
}
let config90days = {
  bondLimit: 250,
  bondActivePeriod: 604800, // 604800 - week
  bondToClaimPeriod: 3600,
  discountBasisPoints: 2500,
  bondStorageAddress: "0x9E8bcf8360Da63551Af0341A67538c918ba81007",
  tokenPriceFeedAddress: "0xe9cF2EEDd15a024CEa69B29F6038A02aD468529B",
  gtonPriceFeedAddress: "0xc28c12150CB0f79a03f627c07C54725F6c397608",
  tokenAddress: "0xd0011de099e514c2094a510dd0109f91bf8791fa",
  gtonAddress: "0xc4d0a76ba5909c8e764b67acf7360f843fbacb2d",
  stakedGtonAddress: "0x314650ac2876c6B6f354499362Df8B4DC95E4750",
  bondTypeString: "7d"
}

let config = configWeek

async function deployAndVerifyBonding() {

  const factory = await ethers.getContractFactory("GTONTwapBondingETH")
  const contract = await factory.deploy(
    config.bondLimit,
    config.bondActivePeriod,
    config.bondToClaimPeriod,
    config.discountBasisPoints,
    config.bondStorageAddress,
    config.tokenPriceFeedAddress,
    config.gtonPriceFeedAddress,
    config.tokenAddress,
    config.gtonAddress,
    config.stakedGtonAddress,
    ethers.utils.formatBytes32String(config.bondTypeString)
  )
  await contract.deployed()

  console.log("Contract deployed to:", contract.address)

  await delay(20000)
  await hre.run("verify:verify", {
    address: contract.address,
    // network: hre.network,
    constructorArguments: [
      config.bondLimit,
      config.bondActivePeriod,
      config.bondToClaimPeriod,
      config.discountBasisPoints,
      config.bondStorageAddress,
      config.tokenPriceFeedAddress,
      config.gtonPriceFeedAddress,
      config.tokenAddress,
      config.gtonAddress,
      config.stakedGtonAddress,
      ethers.utils.formatBytes32String(config.bondTypeString)
    ]
  })
}

async function exampleCallToContract() {
  try {
    let contract = await getETHContract() as GTONTwapBondingETH
    let request = await contract.isBondingActive()
    console.log(request)
  } catch (e) {
    console.log(e)
  }
} 

async function getETHContract() {
  let Bonding = await ethers.getContractFactory("GTONTwapBondingETH")
  return Bonding.attach(
    contract
  )
}

async function deployAndTwapOracle() {
  const factory = await ethers.getContractFactory("TwapOracle")
  const contract = await factory.deploy(
  )
  await contract.deployed()

  console.log("Contract deployed to:", contract.address)

  await delay(20000)
  await hre.run("verify:verify", {
    address: contract.address,
    constructorArguments: [
    ]
  })
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
