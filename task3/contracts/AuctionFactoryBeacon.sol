// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/proxy/beacon/UpgradeableBeacon.sol";
import "@openzeppelin/contracts/proxy/beacon/BeaconProxy.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import "./Auction.sol";


interface IERC20Metadata {
    function decimals() external view returns (uint8);
}
/**
 * @title AuctionFactoryBeacon
 * @notice
 *  - 持有 UpgradeableBeacon（owner 可升级实现）
 *  - 维护 token=>priceFeed，提供 quoteUSD()
 *  - 创建单场拍卖：部署 BeaconProxy，并调用 initialize(...)
 *  - 将 NFT 从卖家安全转入新拍卖合约（需卖家先对工厂授权）
 */
contract AuctionFactoryBeacon is Ownable {
    UpgradeableBeacon public immutable beacon;

    //喂价
    mapping(address=>AggregatorV3Interface) public priceFeeds;
    mapping(address=>bool) public priceFeedSet;

    //记录Auction
    address[] public allAuctions;
    mapping(address=>address[]) public auctionsBySeller;

    // 事件
    event BeaconUpgraded(address indexed newImplementation);
    event AuctionCreated(address indexed seller, address indexed nft, uint256 indexed tokenId, address auction, uint256 duration, uint256 startPriceUsd);
    event PriceFeedUpdated(address indexed token, address indexed feed);

    constructor(address initialImpl) Ownable(msg.sender) {
        require(initialImpl != address(0),"initialImpl = 0");
        // beacon 的owner 是工厂本身
        beacon = new UpgradeableBeacon(initialImpl,address(this));
    }

    // 升级
    function upgradAuctionImpl(address newImpl) external onlyOwner {
        require(newImpl != address(0),"newImpl = 0");
        beacon.upgradeTo(newImpl);
        emit BeaconUpgraded(newImpl);
    }

    // 喂价
    function setPriceFeed(address token,address aggregator) external onlyOwner {
        require(aggregator != address(0),"aggregator = 0");
        priceFeeds[token] = AggregatorV3Interface(aggregator);
        priceFeedSet[token] =true;
        emit PriceFeedUpdated(token,aggregator);
    }

    /// @notice 报价（标准化成 USD 的 8 位小数）
    function quoteUSD(address token,uint256 amount) public view returns (uint256 usd8) {
        AggregatorV3Interface feed =  priceFeeds[token];
        require(address(feed)!= address(0),"no feed");

        (, int256 answer, , , ) = feed.latestRoundData();
        require(answer>0,"bad feed");
        uint8 fdec =  feed.decimals();
        uint8 tdec = token == address(0) ? 18 : IERC20Metadata(token).decimals();

        uint256 raw = Math.mulDiv(amount, uint256(answer), 10 ** tdec);
        //进度转化为8位 usd
        if(fdec>8){
            usd8 = raw /(10**(fdec-8));
        }else if(fdec<8){
            usd8 = raw *(10**(8-fdec));
        }else{
            usd8 = raw;
        }
    }
    /// 创建Auction
    function createAuction(
        address nft,
        uint256 tokenId,
        uint256 duration,
        uint256 startPriceUsd
    ) external returns (address auction) {
        require(nft != address(0),"nft = 0");
        require(duration>=120,"duration < 120");
        require(startPriceUsd>0,"start price = 0");

        bytes memory initData = abi.encodeWithSelector(
            Auction.initialize.selector,
            address(this),
            msg.sender,
            nft,
            tokenId,
            duration,
            startPriceUsd
        );

        auction= address(new BeaconProxy(address(beacon),initData));

        // 将卖家的NFT转给auction
        IERC721(nft).safeTransferFrom(msg.sender,auction,tokenId);

        // 记录auction
        allAuctions.push(auction);
        auctionsBySeller[msg.sender].push(auction);

        emit AuctionCreated(msg.sender,nft,tokenId,auction,duration,startPriceUsd);
    }

    function allAuctionsLength() external view returns (uint256) {
        return allAuctions.length;
    }

    function getAuctionsBySeller(address seller) external view returns (address[] memory) {
        return auctionsBySeller[seller];
    }
}
