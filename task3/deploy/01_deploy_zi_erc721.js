const{ ethers } = require("hardhat");
// 在本地网络中部署 ziToken 合约q
module.exports = async({getNamedAccounts,deployments})=>{
    // 获取配置信息中的 deployer
    const{ deployer } = await getNamedAccounts()
    // 从deployments 中解构出save函数
    const{ save,deploy,log } = deployments

    // 使用deploy 方法进行部署
    log("deploying the ZiERC721Token nft Contract")
    await deploy("ZiERC721Token",{
        contract:"ZiERC721Token",
        from:deployer,
        args:[deployer],
        log:true
    })
    log("deployed the ZiERC721Token nft Contract")
}

module.exports.tags = ["all","ZiERC721Token"]