const{upgrades, ethers} = require("hardhat")

module.exports=async({deployments,getNamedAccounts})=>{
    const{deploy,log,save,getArtifact} = deployments
    const{deployer} = await getNamedAccounts()

    // 获取合约工厂
    const NFTAuctionFactory = await ethers.getContractFactory("NFTAuction")
    log("部署用户地址: ",deployer)
    // 通过部署代理合约部署实现合约
    const NFTAuctionProxy = await upgrades.deployProxy(NFTAuctionFactory,[],{
        initializer:"initialize"
    })
    await NFTAuctionProxy.waitForDeployment()
    const proxyAddr = await NFTAuctionProxy.getAddress()
    log("代理合约地址: ",proxyAddr)

    const implAddr= await upgrades.erc1967.getImplementationAddress(proxyAddr)
    log("实现合约地址: ",implAddr)

    // 4) 将 Proxy 记录到 hardhat-deploy（ABI 用实现合约的 ABI）
    // ✅ 推荐用 deployments.getArtifact 保证拿到标准化的 ABI（数组），
    // 避免 ethers v6 的 interface.format("json") 返回字符串需要再 JSON.parse。
    const nftAuctionAtifact = await getArtifact("NFTAuction")

    await save("NFTAuctionProxy",{
        abi: nftAuctionAtifact.abi,
        address: proxyAddr
    })
}
module.exports.tags = ["all","nftAuctionDeploy"]