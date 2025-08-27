const { upgrades, ethers } = require("hardhat");
module.exports = async({deployments,getNamedAccounts})=>{
    const {deployer} = await getNamedAccounts()
    const { log,read,get,save,deploy }  = deployments
    // 获取AuctionFactoryBeaconProxy合约
    const AuctionFactoryBeaconProxy = await get("AuctionFactoryBeaconProxy")
    // 获取要升级的合约
    const FactoryV2 = await ethers.getContractFactory("AuctionFactoryBeaconV2")
    // 升级AuctionFactoryBeaconProxy合约
    const AuctionFactoryBeaconProxyUpgraded = await upgrades.upgradeProxy(AuctionFactoryBeaconProxy.address,FactoryV2,{call:"getTestName"})
    // 等待升级完成
    await AuctionFactoryBeaconProxyUpgraded.waitForDeployment()
    const proxyUpgradedAddr = await AuctionFactoryBeaconProxyUpgraded.getAddress()
    // 打印升级后的代理合约地址
    log("AuctionFactoryBeaconProxyUpgraded address:: ",proxyUpgradedAddr)
    // 打印升级后的实现合约地址
    const v2implAddr= await upgrades.erc1967.getImplementationAddress(proxyUpgradedAddr)
    log("AuctionFactoryBeaconProxyUpgraded implAddress:: ",v2implAddr)
}
module.exports.tags = ["upgrade","AuctionFactoryBeaconProxyUpgraded"]
