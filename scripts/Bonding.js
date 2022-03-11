async function main() {
  const bondLimit = 250
  const bondActivePeriod = 604800 // 604800 - week
  const bondToClaimPeriod = 3600
  const discountBasisPoints = 2500

  const BondStorageAddress = "0x9E8bcf8360Da63551Af0341A67538c918ba81007"
  const TokenPriceFeedAddress = "0xe9cF2EEDd15a024CEa69B29F6038A02aD468529B"
  const GtonPriceFeedAddress = "0xc28c12150CB0f79a03f627c07C54725F6c397608"
  const TokenAddress = "0xd0011de099e514c2094a510dd0109f91bf8791fa"
  const GtonAddress = "0xc4d0a76ba5909c8e764b67acf7360f843fbacb2d"
  const StakedGtonAddress = "0x314650ac2876c6B6f354499362Df8B4DC95E4750"
  const BondTypeString = "7d"

  const Bonding = await ethers.getContractFactory("BondingETH");
  const bonding = await Bonding.deploy(
    bondLimit,
    bondActivePeriod,
    bondToClaimPeriod,
    discountBasisPoints,
    BondStorageAddress,
    TokenPriceFeedAddress,
    GtonPriceFeedAddress,
    TokenAddress,
    GtonAddress,
    StakedGtonAddress,
    ethers.utils.formatBytes32String(BondTypeString)
  );

  console.log("Bonding contract deployed to:", bonding.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
