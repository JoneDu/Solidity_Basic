require("@nomicfoundation/hardhat-toolbox");
require("@nomicfoundation/hardhat-ethers");
require("hardhat-deploy");
require("hardhat-deploy-ethers");
require("@openzeppelin/hardhat-upgrades");
require("@chainlink/env-enc").config()

const SEPOLIA_RPC_URL = process.env.SEPOLIA_RPC_URL
const PRIVATE_KEY = process.env.PRIVATE_KEY
const PRIVATE_KEY1 = process.env.PRIVATE_KEY1


/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  namedAccounts:{
    deployer:0,
    user1:1,
    user2:2,
  },
  networks:{
    sepolia:{
      url:SEPOLIA_RPC_URL,
      accounts:[PRIVATE_KEY,PRIVATE_KEY1],
      chainId:11155111
    },
    hardhat:{
      // 把测试用的 in-memory 网络也写磁盘
      saveDeployments: true,
      // 指定写到哪个目录
      deployments: "./deployments/hardhat",
      chainId:31337
    }
  }
};
