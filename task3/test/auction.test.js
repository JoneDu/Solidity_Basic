const{deployments,getNamedAccounts,ethers} = require("hardhat")
const {expect} = require("chai")
const helpers = require("@nomicfoundation/hardhat-network-helpers")


let deployer,user1,user2
let mockV3AggregatorEth
let mockV3AggregatorUsdt
let ZiERC721Token
let ZiERC20Token
let Auction
let AuctionV2
let auctionFactoryBeacon
before(async()=>{
    const accounts = await getNamedAccounts()
    deployer = accounts.deployer
    user1 = accounts.user1
    user2 = accounts.user2
    await deployments.fixture(["all"])
    mockV3AggregatorEth = await ethers.getContract("MockV3AggregatorEth",deployer)
    mockV3AggregatorUsdt = await ethers.getContract("MockV3AggregatorUsdt",deployer)
    ZiERC721Token = await ethers.getContract("ZiERC721Token",deployer)
    ZiERC20Token = await ethers.getContract("ZiERC20Token",deployer)
    Auction = await ethers.getContract("Auction",deployer)
    AuctionV2 = await ethers.getContract("AuctionV2",deployer)
    const AuctionFactoryBeaconProxy = await deployments.get("AuctionFactoryBeaconProxy")
    auctionFactoryBeacon = await ethers.getContractAt("AuctionFactoryBeacon",AuctionFactoryBeaconProxy.address)
})

describe("Auction Test",async()=>{ 
    let auction
    it("init mint ERC721,ERC20 and init Aggregator,AuctionFactoryBeacon",async()=>{ 
        await ZiERC20Token.mint(user1,ethers.parseEther("10000"))
        await ZiERC20Token.mint(user2,ethers.parseEther("30000"))
        expect(await ZiERC20Token.balanceOf(user1)).to.equal(ethers.parseEther("10000"))
        expect(await ZiERC20Token.balanceOf(user2)).to.equal(ethers.parseEther("30000"))
        expect(await ZiERC20Token.balanceOf(deployer)).to.equal(ethers.parseEther("20000"))

        await ZiERC721Token.safeMint(deployer,"ipfs://bafkreic25xekhctpgrbjt5t3vzbxg2z3safgr5xmyg3jg7zzdqcld4isye")
        const tokenCount = await ZiERC721Token.balanceOf(deployer)
        expect(tokenCount).to.equal(1)
        expect(await ZiERC721Token.ownerOf(0)).to.equal(deployer)
        await ZiERC721Token.safeMint(user1,"ipfs://bafkreic25xekhctpgrbjt5t3vzbxg2z3safgr5xmyg3jg7zzdqcld4isye")
        const tokenCountUser1 = await ZiERC721Token.balanceOf(user1)
        expect(tokenCountUser1).to.equal(1)
        expect(await ZiERC721Token.ownerOf(1)).to.equal(user1)

        const ZiERC20TokenAddr =  await ZiERC20Token.getAddress()
        await auctionFactoryBeacon.setPriceFeed(ethers.ZeroAddress,mockV3AggregatorEth)
        await auctionFactoryBeacon.setPriceFeed(ZiERC20TokenAddr,mockV3AggregatorUsdt)
        expect(await auctionFactoryBeacon.priceFeedSet(ethers.ZeroAddress)).to.equal(true)
        expect(await auctionFactoryBeacon.priceFeedSet(ZiERC20TokenAddr)).to.equal(true)
    })
    // 测试AuctionFactoryBeacon 报价
    it("AuctionFactoryBeacon quoteUSD",async()=>{
        const usd8= await auctionFactoryBeacon.quoteUSD(ethers.ZeroAddress,ethers.parseEther("1"))
        expect(usd8).to.equal("400000000000")
        const ZiERC20TokenAddr =  await ZiERC20Token.getAddress()
        const usd8_1= await auctionFactoryBeacon.quoteUSD(ZiERC20TokenAddr,ethers.parseEther("1"))
        expect(usd8_1).to.equal("100000000")
        const usd8_2= auctionFactoryBeacon.quoteUSD("0x7CDA40dF0576215A945647AFafe61EFE4AF56ce1",ethers.parseEther("1"))
        await expect(usd8_2).to.be.revertedWith("no feed")
    })

    // 升级FactoryBeacon后,测试报价数据是否存在
    it("AuctionFactoryBeacon upgrade",async()=>{
        // 这里手动升级,不能再使用fixture 否则会把之前的all fixture 重置了
        // 获取AuctionFactoryBeaconProxy合约
        const AuctionFactoryBeaconProxy = await deployments.get("AuctionFactoryBeaconProxy")
        // 获取要升级的合约
        const FactoryV2 = await ethers.getContractFactory("AuctionFactoryBeaconV2")
        // 升级AuctionFactoryBeaconProxy合约
        const AuctionFactoryBeaconProxyUpgraded = await upgrades.upgradeProxy(AuctionFactoryBeaconProxy.address,FactoryV2,{call:"getTestName"})
        // 等待升级完成
        await AuctionFactoryBeaconProxyUpgraded.waitForDeployment()

        // 将代理合约地址重新attach 到V2合约
        auctionFactoryBeacon = await ethers.getContractAt("AuctionFactoryBeaconV2",AuctionFactoryBeaconProxy.address)


        const ZiERC20TokenAddr =  await ZiERC20Token.getAddress()
        const usd8_1= await auctionFactoryBeacon.quoteUSD(ZiERC20TokenAddr,ethers.parseEther("1"))
        expect(usd8_1).to.equal("100000000")
        const testName = await auctionFactoryBeacon.getTestName()
        expect(testName).to.equal("2.0")
    })


    // 测试AuctionFactoryBeacon 部署Auction
    it("AuctionFactoryBeacon createAuction",async()=>{
        const tx = auctionFactoryBeacon.createAuction(await ZiERC721Token.getAddress(),0,110,10*10**8)
        await expect(tx).to.be.revertedWith("duration < 120")

        const tx1 = auctionFactoryBeacon.createAuction(ethers.ZeroAddress,0,120,10*10**8)
        await expect(tx1).to.be.revertedWith("nft = 0")


        // 授权ERC721 给到工厂
        await ZiERC721Token.approve(auctionFactoryBeacon.getAddress(),0)
        const tx2 =await auctionFactoryBeacon.createAuction(await ZiERC721Token.getAddress(),0,120,100*10**8)
        const receipt = await tx2.wait();

        // 2. 从日志解析
        const event = receipt.logs.find(
        (log) => log.fragment && log.fragment.name === "AuctionCreated"
        );
        const auctionAddress = event.args.auction;
        // console.log("auctionAddress: ",auctionAddress)
        // 3. 断言
        expect(auctionAddress).to.be.properAddress;

        const aa =  await auctionFactoryBeacon.getAuctionsBySeller(deployer)
        expect(aa).to.include(auctionAddress)


    })

    // 升级Auction 合约
    it("Auction upgrade",async()=>{
        // auction 升级 V2前 拿到AuctionV2 实际上是信标指向了Auction,所以调用不到hello方法.
        const aa =  await auctionFactoryBeacon.getAuctionsBySeller(deployer)
        auction = await ethers.getContractAt("AuctionV2",aa[0])
        // make sure the window is closed
        // 测试环境进行时间推进.如果使用200 这样就不在激活中了.
        // await helpers.time.increase(100)
        // await helpers.mine()   

        const active = await auction.isActive()
        expect(active).to.equal(true)

        const auctionV2 = await ethers.getContract("AuctionV2",deployer)
        // 这里对Auction 进行升级.
        await auctionFactoryBeacon.upgradAuctionImpl(auctionV2)
        const h = await auction.hello()
        expect(h).to.equal("hello Test!")
    })

    
/* ---------- 成功场景 ---------- */

  it("ETH bid higher than startPriceUSD", async () => {
    const bidEth = ethers.parseEther("0.03"); // ≈ 0.03 * 4000 = 120 USD ≥ 100 USD
    const signerUser1 = await ethers.getSigner(user1);
    await auction.connect(signerUser1).placeBid(bidEth, ethers.ZeroAddress, { value: bidEth })

    expect(await auction.highestBidder()).to.equal(user1);
    expect(await auction.highestBid()).to.equal(bidEth);
  });

  it("ERC20 bid higher than current highest", async () => {
    const signerUser1 = await ethers.getSigner(user1);
    const signerUser2 = await ethers.getSigner(user2);

    // 已经mint 了30000给到 user2
    // user1 10000
    const ZiERC20TokenAddr = await ZiERC20Token.getAddress()
    // User2 needs to approve the auction contract to spend their tokens
    await ZiERC20Token.connect(signerUser2).approve(auction.getAddress(), ethers.parseEther("500"));
    // console.log(await auctionFactoryBeacon.quoteUSD(ZiERC20TokenAddr,ethers.parseEther("100")));
    
    // 第一次出价 100 USDT 最高还是signerUser1
    const tx= auction.connect(signerUser2).placeBid(ethers.parseEther("101"), ZiERC20TokenAddr);
    await expect(tx).to.revertedWith("below highest bid");
    expect(await auction.highestBidder()).to.equal(user1);
    expect(await auction.highestBid()).to.equal(ethers.parseEther("0.03"));

    // 第二次更高 200 USDT
    await auction.connect(signerUser2).placeBid(ethers.parseEther("200"),ZiERC20TokenAddr)
    expect(await auction.highestBidder()).to.equal(user2);
    expect(await auction.highestBid()).to.equal(ethers.parseEther("200"));
  });


//   /* ---------- 失败场景 ---------- */
  it("revert: bid below startPriceUSD", async () => {
    const signerUser1 = await ethers.getSigner(user1);
    await expect(
      auction.connect(signerUser1).placeBid(
        ethers.parseEther("0.02"), // ≈ 80 USD < 100
        ethers.ZeroAddress,
        { value: ethers.parseEther("0.02") }
      )
    ).to.be.revertedWith("below start price!");
  });

  it("revert: auction ended", async () => {
    // await helpers.time.increase(120)
    // await helpers.mine()   
    const signerUser1 = await ethers.getSigner(user1);

    // await expect(
    //   auction.connect(signerUser1).placeBid(ethers.parseEther("1"), ethers.ZeroAddress, { value: ethers.parseEther("1") })
    // ).to.be.revertedWith("this auction is ended");
  });

  it("revert: no price feed for unknown token", async () => {
    const signerUser2 = await ethers.getSigner(user2);

    await expect(
      auction.connect(signerUser2).placeBid(ethers.parseEther("1"), user1 /* 随意地址 */, { value: ethers.parseEther("1") })
    ).to.be.revertedWith("no price feed");
  });

    it("endAuction-revert: auction not ended", async () => {
    // await helpers.time.increase(120)
    // await helpers.mine()   
    const signerUser1 = await ethers.getSigner(user1);

    await expect(
      auction.connect(signerUser1).endAuction()
    ).to.be.revertedWith("auction not ended");
  });

    it("endAuction: auction ended", async () => {
    await helpers.time.increase(120)
    await helpers.mine()   
    const signerUser1 = await ethers.getSigner(user1);

    await auction.connect(signerUser1).endAuction()
  });


    it("endAuction-revert: auction already ended", async () => {
    await helpers.time.increase(120)
    await helpers.mine()   
    const signerUser2 = await ethers.getSigner(user2);

    await expect( auction.connect(signerUser2).endAuction()).to.be.revertedWith("auction already ended!");
  });
})