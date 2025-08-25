// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";



// 这是一个NFT拍卖场，会有多个拍卖
contract NFTAuction {
     // 创建一个结构体用来存储拍卖信息
     struct Auction {
        uint256 auctionId;
        //卖家
        address payable seller;
        // 时间信息
        uint256 startTime;
        uint256 duration;
        bool ended;

        //要卖的nft 信息
        address nftAddress;
        uint256 tokenId;
        // 价格信息
        uint256 startPrice;// 使用Eth作为token
        address paymentTokenAddress;
        address highestBidder;
        uint256 highestBid;
     }

     // 拍卖计数器
     uint256 nextAuctionNum;

     //每场拍卖的信息
     mapping (uint256 => Auction) public auctions;
     address public admin;

     // 存储价格转换对
     // ETH/USD ...
     mapping(address=>AggregatorV3Interface) public priceFeeds;

     // 创建拍卖
     function createAuction(
        address _nftAddr,
        uint256 _tokenId,
        uint256 _duration,
        uint256 _startPrice,
        address _paymentToken
        )  public {
        // 权限，参数交验，只有admin
        require(msg.sender == admin,"createAuction only admin can do it!");
        require(_duration>=120,"auction duration must great than 120s");
        require(_startPrice>0,"start price must great than 0");

        // 将NFT转移到本地址
        IERC721(_nftAddr).safeTransferFrom(msg.sender,address(this),_tokenId);

        nextAuctionNum++;
        // 创建Auction
        auctions[nextAuctionNum]=Auction({
            auctionId:nextAuctionNum,
            seller:payable(msg.sender),
            startTime:block.timestamp,
            duration:_duration,
            ended:false,
            nftAddress:_nftAddr,
            tokenId:_tokenId,
            startPrice:_startPrice,
            paymentTokenAddress:_paymentToken,
            highestBidder:address(0),
            highestBid:0
        });
     }


    function setDataFeeds(address _paymentTokenAddr,address _dataFeedAddr) public returns (bool) {
        priceFeeds[_paymentTokenAddr]=AggregatorV3Interface(_dataFeedAddr);
        return true;
    }

    function getChainlinkDataFeedLatestAnswer(address _paymentTokenAddr) public view returns (int) {
        AggregatorV3Interface dataFeed = priceFeeds[_paymentTokenAddr];
        require(address(dataFeed)!=address(0),"dataFeed not set");

        (
            /* uint80 roundId */,
            int256 answer,
            /*uint256 startedAt*/,
            /*uint256 updatedAt*/,
            /*uint80 answeredInRound*/
        ) = dataFeed.latestRoundData();
        return answer;
    }

     // 拍卖出价,要支持ERC20 
     function placeBid(uint256 _auctionId,uint256 _amount,address _paymentTokenAddr) external payable {
        // 拍卖是否存在，拍卖是否开始结束
        Auction storage auction =  auctions[_auctionId];
        require(auction.seller != address(0),"this auction is not found");
        require(block.timestamp>= auction.startTime,"this auction is not start");
        require(block.timestamp<= auction.startTime+auction.duration,"this auction is already end");

        // 需要当前出价要大于目前最高的出价,和起拍价格.
        // 使用 openzepplin 的喂价系统.获取预言机中的 美元换算价格.
        // 为了方便计算,需要把价格都统一转换成美元
        uint payValue;
        if(_paymentTokenAddr==address(0)){
            // 如果_paymentTokenAddr 是0️⃣ 支付的是 ETH,msg.value 要等于 _amount
            require(msg.value == _amount,"payment value is not valid");
            payValue = _amount * uint(getChainlinkDataFeedLatestAnswer(_paymentTokenAddr));
        }else{
            // 如果_paymentTokenAddr 不是zero,说明支付的是ERC20,调用者要支付ERC20 到本合约账户中.
            payValue = _amount * uint(getChainlinkDataFeedLatestAnswer(_paymentTokenAddr));
            IERC20(_paymentTokenAddr).transferFrom(msg.sender,address(this),_amount);
        }
        
        uint highestValue = auction.highestBid * uint(getChainlinkDataFeedLatestAnswer(auction.paymentTokenAddress));
        uint startPriceValue = auction.startPrice * uint(getChainlinkDataFeedLatestAnswer(address(0)));
        require(payValue>=startPriceValue && payValue>highestValue,"Bid must higher than highest bid!");
        
        // 退还最高出价者代币
        if(auction.highestBid>0){
            if(auction.paymentTokenAddress == address(0)){
                payable(auction.highestBidder).transfer(auction.highestBid);
            }else{
                // 退回转入的ERC20
                IERC20(auction.paymentTokenAddress).transfer(auction.highestBidder,auction.highestBid);
            }
        }

        // 更新最高出价者和最高价格.
        auction.highestBidder = payable(msg.sender);
        auction.highestBid = _amount;
        auction.paymentTokenAddress = _paymentTokenAddr;
     }

     // 结束拍卖

}