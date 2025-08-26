const{ ethers,upgrades } = require("hardhat")
module.exports = async({deployments,getNamedAccounts})=>{
    const {deployer} = await getNamedAccounts()
    const { log,read,get,save,getArtifact }  = deployments
    log("V2合约部署者: ",deployer)

    // 获取代理合约地址
    const nftAuctionProxy = await get("NFTAuctionProxy")
    const proxyAddr =  nftAuctionProxy.address
    log("代理合约地址: ",proxyAddr)

    // 获取V2 的合约工厂
    const nftAuctionV2Factory = await ethers.getContractFactory("NFTAuctionV2")
    // 进行升级
    const upgraded = await upgrades.upgradeProxy(proxyAddr,nftAuctionV2Factory,{
        call:{fn:"setTestName",args:["mm"]}
    })
    await upgraded.waitForDeployment()

    // V2实现合约地址
    const implAddrV2 =  await upgrades.erc1967.getImplementationAddress(proxyAddr)
    log("V2实现合约地址: ",implAddrV2)


}

module.exports.tags = ["all","nftAuctionUpgrade"]