const{upgrades, ethers} = require("hardhat")

module.exports=async({deployments,getNamedAccounts})=>{
    const{deploy,log,save,getArtifact} = deployments
    const{deployer} = await getNamedAccounts()

    log("Auction deploying")
    const Auction = await deploy("Auction",{
        contract:"Auction",
        from:deployer,
        args:[],
        log:true
    })
    log("Auction deployed address:: ",Auction.address)

    const AuctionV2 = await deploy("AuctionV2",{
        contract:"AuctionV2",
        from:deployer,
        args:[],
        log:true
    })
    log("AuctionV2 deployed address:: ",AuctionV2.address)
}
module.exports.tags = ["all","Auction"]
