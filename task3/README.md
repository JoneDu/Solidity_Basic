# NFT拍卖平台智能合约项目

本项目是一个基于Hardhat的Solidity智能合约开发项目，用于演示基本的智能合约开发、部署和测试流程。项目实现了一个NFT拍卖平台，支持可升级合约和跨链功能。

## 项目概述

项目背景: 本项目是一个基于 Hardhat 的 Solidity 智能合约开发项目，用于演示基本的智能合约开发、部署和测试流程。
目标用户: 区块链开发者、智能合约学习者。
核心问题: 提供一个基础框架，帮助开发者快速上手 Hardhat 工具，进行合约开发、部署和测试。

## 主要功能

- 智能合约开发: 包括 Auction、AuctionFactoryBeacon 等合约
- 合约部署: 使用 Hardhat部署脚本进行合约部署
- 合约测试: 提供测试脚本验证合约逻辑和升级功能
- 支持合约版本升级（通过 Beacon 模式）
- 提供 Mock 合约用于本地测试（如 MockV3Aggregator）
- 包含 ERC20 和 ERC721 标准代币合约

## 项目结构

```
.
├── contracts/
│   ├── mock/
│   │   ├── MockV3Aggregator.sol      # 用于测试的模拟Chainlink价格预言机
│   │   ├── ZiERC20Token.sol          # 示例ERC20代币合约
│   │   └── ZiERC721Token.sol         # 示例ERC721 NFT合约
│   ├── Auction.sol                   # 核心拍卖合约
│   ├── AuctionFactoryBeacon.sol      # 拍卖工厂合约（支持可升级性）
│   ├── AuctionFactoryBeaconV2.sol    # 升级版拍卖工厂合约
│   └── AuctionV2.sol                 # 升级版拍卖合约
│
├── deploy/
│   ├── 00_deploy_mockAggerator.js    # 部署模拟价格预言机
│   ├── 01_deploy_zi_erc721.js        # 部署ZiERC721Token合约
│   ├── 02_deploy_zi_erc20.js         # 部署ZiERC20Token合约
│   ├── 03_deploy_Auction.js          # 部署Auction合约
│   ├── 04_deploy_Auction_factory.js  # 部署Auction工厂合约
│   └── 05_upgrade_Auction_factory.js # 升级Auction工厂合约
│
├── test/
│   └── auction.test.js              # 拍卖功能测试脚本
│
├── helper-hardhat-config.js         # 配置常量
└── hardhat.config.js                # Hardhat配置文件
```

## 前提条件

- Node.js v18.x 或更高版本
- npm 或 yarn
- Hardhat

## 安装

1. 克隆仓库：
   ```bash
   git clone <repository-url>
   cd task3
   ```

2. 安装依赖：
   ```bash
   npm install
   ```

## 部署

### 本地开发网络

1. 启动本地Hardhat网络：
   ```bash
   npx hardhat node
   ```

2. 在新终端中部署合约：
   ```bash
   npx hardhat deploy --network localhost
   ```

### 测试网部署

1. 在`.env`文件中配置环境变量：
   ```env
   SEPOLIA_RPC_URL=<your-sepolia-rpc-url>
   PRIVATE_KEY=<your-private-key>
   ```

2. 部署到Sepolia测试网：
   ```bash
   npx hardhat deploy --network sepolia
   ```

## 测试

运行测试套件：
```bash
npx hardhat test
```

运行带gas报告的测试：
```bash
REPORT_GAS=true npx hardhat test
```


## 合约可升级性

合约使用信标代理模式实现，允许安全无缝的升级：

1. 部署新的实现合约
2. 调用工厂的`upgradAuctionImpl`函数升级实现
3. 所有现有拍卖自动使用新实现

## 核心组件

### 拍卖合约
- 处理核心拍卖逻辑
- 管理NFT存入和提取
- 处理出价并确定获胜者
- 支持ETH和ERC20代币出价

### 拍卖工厂
- 使用信标代理模式创建新的拍卖合约
- 管理用于出价估值的价格喂价
- 处理跨链出价转发

### 跨链拍卖
- 基本拍卖的扩展，集成了CCIP
- 接收和处理跨链出价
- 实现了CCIP消息接收接口

## 安全考虑

- 使用OpenZeppelin的安全合约模板
- 实现ReentrancyGuard以防止重入攻击
- 使用SafeERC20进行安全的ERC20代币转账
- 所有外部调用都经过适当的验证检查

## 未来改进

1. 实现跨链退款功能
2. 添加更复杂的出价策略支持
3. 为流行的NFT集合实现拍卖扩展
4. 添加DAO治理以管理平台参数