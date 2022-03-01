async function main() {
    // We get the contract to deploy
    const Bonding = await ethers.getContractFactory("BondingETH");
    const bonding = await Bonding.deploy(
        250,
        604800, //week
        86400,
        2500, // discount
        "0xd9c72C722e35d6C773695412a232969AE0a6c898",
        "0xe9cF2EEDd15a024CEa69B29F6038A02aD468529B",
        "0xc28c12150CB0f79a03f627c07C54725F6c397608",
        "0xd0011de099e514c2094a510dd0109f91bf8791fa",
        "0xc4d0a76ba5909c8e764b67acf7360f843fbacb2d",
        "0x314650ac2876c6B6f354499362Df8B4DC95E4750",
        ethers.utils.formatBytes32String("7d")
    );
  
    console.log("Greeter deployed to:", bonding.address);
  }
  
  main()
    .then(() => process.exit(0))
    .catch((error) => {
      console.error(error);
      process.exit(1);
    });