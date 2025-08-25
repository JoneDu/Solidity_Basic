const { network } = require("hardhat")
const{DECIMAL,ETH_INITIAL_ANSWER,USDT_INITIAL_ANSWER,developmentChains} = require("../helper-hardhat-config")
const { Contract } = require("ethers")

module.exports=async ({deployments,getNamedAccounts})=>{
    const {deploy,log,save} = deployments
    const {deployer} = await getNamedAccounts()
    log(network.name)
    if(developmentChains.includes(network.name)){
        await deploy("MockV3AggregatorEth", {
        contract:"MockV3Aggregator",
        from: deployer,
        args: [DECIMAL, ETH_INITIAL_ANSWER],
        log: true
        })

        await deploy("MockV3AggregatorUsdt", {
        contract:"MockV3Aggregator",
        from: deployer,
        args: [DECIMAL, USDT_INITIAL_ANSWER],
        log: true
        })
        // 将以上两个合约save
        log("MockV3Aggregator deployed")
    }else{
        log("network is not test,mock deploy is skipped")
    }    
}

module.exports.tags = ["all", "mock"]