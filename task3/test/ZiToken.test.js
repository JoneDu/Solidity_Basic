const{deployments,getNamedAccounts,ethers} = require("hardhat")
const {expect} = require("chai")

let ziToken,deployer,user1,user2

before(async()=>{
    const accounts = await getNamedAccounts()
    deployer = accounts.deployer
    user1 = accounts.user1
    user2 = accounts.user2
    await deployments.fixture(["ZiToken"])
    ziToken = await ethers.getContract("ZiToken",deployer)
})

describe("ZiToken Test",async()=>{ 

    it("ZiToken mint",async()=>{ 
        await ziToken.safeMint(deployer,"ipfs://bafkreic25xekhctpgrbjt5t3vzbxg2z3safgr5xmyg3jg7zzdqcld4isye")
        const tokenCount = await ziToken.balanceOf(deployer)
        expect(tokenCount).to.equal(1)
        expect(await ziToken.ownerOf(0)).to.equal(deployer)
            

    })
    it("ZiToken transfer",async()=>{
        await ziToken.transferFrom(deployer,user1,0)
        expect(await ziToken.ownerOf(0)).to.equal(user1)
    })
})