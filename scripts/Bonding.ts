
const hre = require("hardhat");
import { run, ethers } from "hardhat"
import { BondingETH } from "../types/BondingETH"

async function main() {
  run("compile");
  await deployAndVerifyBonding()
}

let ethBondingConfig = {
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

let config = ethBondingConfig

async function deployAndVerifyBonding() { 

  const factory = await ethers.getContractFactory("BondingETH")
  const bonding = await factory.deploy(
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
  );

  console.log("Bonding contract deployed to:", bonding.address);

  return // Unfortunately currently ftmscan has a bug and automatic verification fails
  // The delay is necessary to avoid "the address does not have bytecode" error
  await delay(50000);

  await hre.run("verify:verify", {
    address: bonding.address,
    network: hre.network,
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
  });
}

async function exampleCallToContract() {
  try {
    let contract = await getETHContract() as BondingETH
    let request = await contract.isBondingActive()
    console.log(request)
  } catch (e) {
    console.log(e);
  }
} 

async function getETHContract() {
  let Bonding = await ethers.getContractFactory("BondingETH");
  return Bonding.attach(
    "0xc7b266aafcea5c1d8e6d90339a73cca34e476492" // Latest hourly bonding contract
  )
}

const delay = ms => new Promise(res => setTimeout(res, ms));

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
