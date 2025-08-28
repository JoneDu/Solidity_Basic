// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

// 拍卖要调用的工厂接口,这里只有内部使用.
interface IAuctionFactory {
    function quoteUSD(address token, uint256 amount) external view returns (uint256 usd8);
    function priceFeedSet(address token) external view returns (bool);
    function owner() external view returns (address);
}

// 这是一个拍卖合约,支持工厂模式创建管理,并且可升级.
contract Auction is Initializable,ReentrancyGuardUpgradeable,IERC721Receiver {
    using SafeERC20 for IERC20;
    // 业务数据
    address public factory;
    address payable public seller;
    // 要拍卖的NFT
    address public nftAddress;
    uint256 public tokenId;
    // 入仓时间
    uint256 public startTime;
    uint256 public duration; // 秒
    bool public ended;
    bool public nftDeposited;// NFT是否存入

    // 价格信息
    uint256 public startPriceUSD; //起拍价(USD,8位小数)

    //最高价信息
    address public highestBidder;
    uint256 public highestBid;         // 原来币种出价
    address public highestPaymentToken;// 0 表示ETH

    // 事件
    event AuctionInitialized(address indexed factory, address indexed seller, address indexed nft, uint256 tokenId, uint256 duration, uint256 startPriceUsd);
    event NftDeposited(address indexed nft, uint256 indexed tokenId, uint256 startTime);
    event BidPlaced(address indexed bidder, address indexed payToken, uint256 amount, uint256 usdValue);
    event Refunded(address indexed prevBidder, address indexed payToken, uint256 amount);
    event AuctionEnded(address indexed winner, address indexed payToken, uint256 amount);

    /// @dev 初始化创建拍卖：仅在 Proxy 部署后由工厂调用一次
    function initialize (
        address _factory,
        address payable _seller,
        address _nftAddress,
        uint256 _tokenId,
        uint256 _duration,
        uint256 _startPriceUSD
    )  external initializer {
        // param valid
        require(_factory!= address(0),"factory = 0");
        require(_seller != address(0),"seller = 0");
        require(_nftAddress!= address(0),"nft = 0");
        require(_duration>=120,"duration < 120");
        require(_startPriceUSD>0,"startPrice = 0");
        //初始化赋值
        __ReentrancyGuard_init();
        factory = _factory;
        seller = _seller;
        nftAddress = _nftAddress;
        tokenId = _tokenId;
        duration = _duration;
        startPriceUSD = _startPriceUSD;
        // 发送事件
        emit AuctionInitialized(_factory,_seller,_nftAddress,_tokenId,_duration,_startPriceUSD);
    }

    // NFT 入仓：开始计时
    function onERC721Received(
        address /*operator*/,
        address /*from*/,
        uint256 _tokenId,
        bytes calldata /*data*/
    ) external override returns (bytes4) {
        require(msg.sender == nftAddress, "wrong nft"); // nft自动回调检查,防止被其他账户调用的安全检查
        require(_tokenId == tokenId, "wrong tokenId");
        require(!nftDeposited, "already deposited");

        nftDeposited = true;
        startTime = block.timestamp;

        emit NftDeposited(nftAddress, tokenId, startTime);
        return this.onERC721Received.selector;
    }

    // 视图检查
    function isActive() public view returns (bool) {
        if(ended || !nftDeposited) return false;
        return block.timestamp>=startTime && block.timestamp <= startTime+duration;
    }

     // 拍卖出价,要支持ERC20 
     function placeBid(
        uint256 _amount,
        address _paymentToken
        ) external payable nonReentrant{
        require(nftDeposited,"nft not Desposited");
        require(block.timestamp>= startTime,"this auction is not start");
        require(block.timestamp<= startTime+duration,"this auction is ended");
        require(!ended,"this auction is ended!");
        require(_amount>0,"amount = 0");

        // 查看工厂中是否已经有相关喂价
        require(IAuctionFactory(factory).priceFeedSet(_paymentToken),"no price feed");

        if(_paymentToken == address(0)){
            require(_amount == msg.value,"ETH! = amount");
        }else{
            IERC20(_paymentToken).safeTransferFrom(msg.sender,address(this),_amount);
        }

        uint256 payUsd =  IAuctionFactory(factory).quoteUSD(_paymentToken,_amount);
        require(payUsd>=startPriceUSD,"below start price!");

        uint256 highestPayUsd;
        if(highestBidder != address(0)){
            highestPayUsd =  IAuctionFactory(factory).quoteUSD(highestPaymentToken,highestBid);
        }
        require(payUsd>highestPayUsd,"below highest bid");

        // 记录旧的最高价
        address prevBidder = highestBidder;
        uint256 prevBid = highestBid;
        address prevPaymentToken = highestPaymentToken;
        // 更新最高价
        highestBidder = msg.sender;
        highestBid = _amount;
        highestPaymentToken = _paymentToken;

        // 退款给旧的最高者
        if(prevBidder != address(0) && prevBid>0){
            if(prevPaymentToken == address(0)){
                (bool ok,) = payable(prevBidder).call{value:prevBid}("");
                require(ok,"refund ETH fail");
            }else{
                IERC20(prevPaymentToken).safeTransfer(prevBidder,prevBid);
            }
            emit Refunded(prevBidder,prevPaymentToken,prevBid);
        }
        
        emit BidPlaced(highestBidder,highestPaymentToken,highestBid,payUsd);
     }

     // 结束拍卖
     // 任何人在拍卖结束时候都可以进行拍卖
     // 如果出价没有满足starPrice ,NFT 退还给seller
     // 否则将NFT 给到最高出价人,并把钱给到seller.
     function endAuction() external nonReentrant{
        require(nftDeposited,"nft not deposited");
        require(block.timestamp>= startTime + duration,"auction not ended");
        require(!ended,"auction already ended!");

        ended = true;

        if(highestBid == 0 && highestBidder == address(0)){
            IERC721(nftAddress).safeTransferFrom(address(this),seller,tokenId);
        }else{
            IERC721(nftAddress).safeTransferFrom(address(this),highestBidder,tokenId);
            // 将买家token 转给 seller
            if(highestPaymentToken == address(0)){
                (bool ok,) = payable(seller).call{value:highestBid}("");
                require(ok,"pay seller ETH fail!");
            }else{
                IERC20(highestPaymentToken).safeTransfer(seller,highestBid);
            }
        }

        emit AuctionEnded(highestBidder,highestPaymentToken,highestBid);
     }

     receive() external payable{}
}