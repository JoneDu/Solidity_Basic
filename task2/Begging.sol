// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Begging{
    address public owner;
    mapping(address=>uint256) public donorBalances;
    uint256 public deployTimestamp;
    uint256 public lockTime;

    event Donation(address _donor,uint256 _amount);

    constructor(uint256 _lockTime){
        owner = msg.sender;
        lockTime = _lockTime;
        deployTimestamp = block.timestamp;
    }

    modifier onlyOwner{
        require(msg.sender==owner,"your are not contract owner do not allow do that!");
        _;
    }
    modifier timeLimiter{
        require(block.timestamp<=deployTimestamp+lockTime,"donate time up");
        _;
    }

    function donate()public payable timeLimiter returns(bool){
        //允许用户向合约发送以太币，并记录捐赠信息。
        uint256 amount = msg.value;
        require(amount>0,"no eth send");
        donorBalances[msg.sender] += amount;
        emit Donation(msg.sender,amount);
        return true;
    }

    function withdraw()external onlyOwner returns(bool){
        // 允许合约所有者提前所有资金,address.transfer 实现支付和提款
        require(block.timestamp>=deployTimestamp+lockTime,"donate time not up");
        uint256 amount = address(this).balance;
        require(amount>0,"the balance is zero");
        payable (owner).transfer(amount);
        return true;
    }

    function getDonation(address _donor) external view  returns(uint256){
        //允许查询某个地址的捐赠金额
        return donorBalances[_donor];
    }

    function top3Donors(address[] calldata _donors) 
    external
    view
    returns(address[3] memory addrs,uint256[3] memory amounts){
        // 使用前端传入的活跃账户，或者筛选过的账户。
        uint256[3] memory topAmounts;
        address[3] memory topAddrs;
        for (uint256 i = 0; i<_donors.length; i++) 
        {
            address donor = _donors[i];
            uint256 amount = donorBalances[donor];
            if(amount>topAmounts[0]){
                topAmounts[2]=topAmounts[1];
                topAddrs[2]=topAddrs[1];
                topAmounts[1]=topAmounts[0];
                topAddrs[1]=topAddrs[0];
                topAmounts[0]=amount;
                topAddrs[0]=donor;
            }else if(amount>topAmounts[1]){
                topAmounts[2]=topAmounts[1];
                topAddrs[2]=topAddrs[1];
                topAmounts[1]=amount;
                topAddrs[1]=donor;
            }else if(amount>topAmounts[2]){
                topAmounts[2]=amount;
                topAddrs[2]=donor;
            }
        }
        return (topAddrs,topAmounts);
    }

}