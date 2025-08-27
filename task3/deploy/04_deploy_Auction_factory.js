const{ ethers,upgrades } = require("hardhat")
module.exports = async({deployments,getNamedAccounts})=>{
    const {deployer} = await getNamedAccounts()
    const { log,read,get,save,deploy }  = deployments

    // 获取Auction合约
    const Auction = await get("Auction")

    // 部署AuctionFactoryBeacon
    const AuctionFactoryBeacon = await deploy("AuctionFactoryBeacon",{
        contract:"AuctionFactoryBeacon",
        from:deployer,
        args:[Auction.address],
        log:true
    })
    log("AuctionFactoryBeacon deployed address:: ",AuctionFactoryBeacon.address)

    
}

module.exports.tags = ["all","AuctionFactoryBeacon"]
