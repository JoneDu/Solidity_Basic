module.exports = async({deployments,getNamedAccounts})=>{
    const{deploy,log}= deployments
    const {deployer} = await getNamedAccounts()

    log("ziERC20Token deploying")
    const ziERC20Token = await deploy("ZiERC20Token",{
        from:deployer,
        args:[],
        log:true
    })
    log("ziERC20Token deployed address:: ",ziERC20Token.address)
}
module.exports.tags = ["all","ZiERC20Token"]