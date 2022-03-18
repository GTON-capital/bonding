// hardhat.config.ts

import "@nomiclabs/hardhat-etherscan"
import "@nomiclabs/hardhat-solhint"
import "@tenderly/hardhat-tenderly"
import "@nomiclabs/hardhat-waffle"
import "hardhat-abi-exporter"
import "hardhat-deploy"
import "hardhat-deploy-ethers"
import "hardhat-gas-reporter"
import "hardhat-typechain"
import "hardhat-watcher"
import "solidity-coverage"

import { resolve } from "path";
import { config as dotenvConfig } from "dotenv";
dotenvConfig({ path: resolve(__dirname, "./.env") });

import { HardhatUserConfig } from "hardhat/types"

let accounts = {
  accounts: [process.env.PRIVATEKEY]
}

const config: HardhatUserConfig = {
  abiExporter: {
    path: "./abi",
    clear: false,
    flat: true,
    // only: [],
    // except: []
  },
  defaultNetwork: "hardhat",
  gasReporter: {
    coinmarketcap: process.env.COINMARKETCAP_API_KEY,
    currency: "USD",
    enabled: process.env.REPORT_GAS === "true",
    excludeContracts: ["contracts/libraries/"],
  },
  mocha: {
    timeout: 20000,
  },
  networks: {
    mainnet: {
      url: `https://mainnet.infura.io/v3/${process.env.INFURA_API_KEY}`,
      gasPrice: 120 * 1000000000,
      chainId: 1,
      ...accounts
    }, 
    localhost: {
      live: false,
      saveDeployments: true,
      tags: ["local"],
    },
    hardhat: {
      forking: {
        enabled: process.env.FORKING === "true",
        url: `https://eth-mainnet.alchemyapi.io/v2/${process.env.ALCHEMY_API_KEY}`,
      },
      live: false,
      saveDeployments: true,
      tags: ["test", "local"],
      },
    ftmTestnet: {
      chainId: 4002,
      url: "https://rpc.testnet.fantom.network",
      ...accounts
    },
    ropsten: {
      url: `https://ropsten.infura.io/v3/${process.env.INFURA_API_KEY}`,
      chainId: 3,
      live: true,
      saveDeployments: true,
      tags: ["staging"],
      gasPrice: 5000000000,
      gasMultiplier: 2,
      ...accounts
    },
    rinkeby: {
      url: `https://rinkeby.infura.io/v3/${process.env.INFURA_API_KEY}`,
      chainId: 4,
      live: true,
      saveDeployments: true,
      tags: ["staging"],
      gasPrice: 5000000000,
      gasMultiplier: 2,
      ...accounts
    },
    goerli: {
      url: `https://goerli.infura.io/v3/${process.env.INFURA_API_KEY}`,
      chainId: 5,
      live: true,
      saveDeployments: true,
      tags: ["staging"],
      gasPrice: 5000000000,
      gasMultiplier: 2,
      ...accounts
    },
    kovan: {
      url: `https://kovan.infura.io/v3/${process.env.INFURA_API_KEY}`,
      chainId: 42,
      live: true,
      saveDeployments: true,
      tags: ["staging"],
      gasPrice: 20000000000,
      gasMultiplier: 2,
      ...accounts
    },
    polygon: {
      url: "https://rpc-mainnet.maticvigil.com",
      chainId: 137,
      live: true,
      saveDeployments: true,
      ...accounts
    },
    polygonMumbai: {
      url: "https://rpc-mumbai.maticvigil.com/",
      chainId: 80001,
      live: true,
      saveDeployments: true,
      tags: ["staging"],
      gasMultiplier: 2,
      ...accounts
    },
    bsc: {
      url: "https://bsc-dataseed.binance.org",
      chainId: 56,
      live: true,
      saveDeployments: true,
      ...accounts
    },
    "bsc-testnet": {
      url: "https://data-seed-prebsc-2-s3.binance.org:8545",
      chainId: 97,
      live: true,
      saveDeployments: true,
      tags: ["staging"],
      gasMultiplier: 2,
      ...accounts
    },
  },
  etherscan: {
    apiKey: {
        mainnet: process.env.ETHERSCAN,
        ropsten: process.env.ETHERSCAN,
        rinkeby: process.env.ETHERSCAN,
        goerli: process.env.ETHERSCAN,
        kovan: process.env.ETHERSCAN,
        // ftm
        opera: process.env.FTMSCAN,
        ftmTestnet: process.env.FTMSCAN,
        // polygon
        polygon: process.env.POLYGONSCAN,
        polygonMumbai: process.env.POLYGONSCAN,
    }
  },
  paths: {
    artifacts: "artifacts",
    cache: "cache",
    deploy: "deploy",
    deployments: "deployments",
    imports: "imports",
    sources: "contracts",
    tests: "test",
  },
  solidity: {
    compilers: [
      {
        version: "0.6.12",
        settings: {
          optimizer: {
            enabled: true,
            runs: 200,
          },
        },
      },
      {
        version: "0.8.0"
      },
      {
        version: "0.8.8"
      },
      {
        version: "0.5.17"
      },
    ],
  },
  tenderly: {
    project: process.env.TENDERLY_PROJECT!,
    username: process.env.TENDERLY_USERNAME!,
  },
  typechain: {
    outDir: "types",
    target: "ethers-v5",
  },
  watcher: {
    compile: {
      tasks: ["compile"],
      files: ["./contracts"],
      verbose: true,
    },
  },
}

export default config
