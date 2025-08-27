const{ ethers,upgrades } = require("hardhat")
const { getArtifactFromFolders } = require("hardhat-deploy/dist/src/utils")
module.exports = async({deployments,getNamedAccounts})=>{
    const {deployer} = await getNamedAccounts()
    const { log,read,get,save,deploy,getArtifact }  = deployments

    // 获取Auction合约
    const Auction = await get("Auction")

    // 透明代理部署AuctionFactoryBeacon
    const Factory = await ethers.getContractFactory("AuctionFactoryBeacon")
    const AuctionFactoryBeacon = await upgrades.deployProxy(Factory,
        [Auction.address],
        {
        initializer:"initialize",
    })
    // 等待部署完成
    await AuctionFactoryBeacon.waitForDeployment()

    // 代理合约地址
    const AuctionFactoryBeaconProxyAddress = await AuctionFactoryBeacon.getAddress()
    log("AuctionFactoryBeaconProxyAddress:: ",AuctionFactoryBeaconProxyAddress)
    // 计算工厂合约实现合约地址
    const AuctionFactoryBeaconImplAddress = await upgrades.erc1967.getImplementationAddress(AuctionFactoryBeaconProxyAddress)
    log("AuctionFactoryBeaconImplAddress:: ",AuctionFactoryBeaconImplAddress)


    const factoryArtifact = await getArtifact("AuctionFactoryBeacon"); // => { abi, bytecode, ... }

    // 保存合约
    await save("AuctionFactoryBeaconProxy",{
        address:AuctionFactoryBeaconProxyAddress,
        abi:factoryArtifact.abi,
    })

}

module.exports.tags = ["all","AuctionFactoryBeaconProxy"]
