// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract BiToken{
    // 声明代币的基本信息
    string public name = "BiToken";
    string public symbol = "BT";
    uint8 public decimals = 18;
    uint256 public totalSupply;
    address owner;

    // 存储每个地址的代币余额
    mapping(address=>uint256) public balances;

    // 存储每个地址，授权给其他地址的代币数量
    mapping(address=> mapping(address=>uint256)) public allowance;    

    // 定义转账事件和授权事件
    event Transfer(address indexed from,address indexed to, uint256 value);
    event Approval(address indexed owner,address indexed spender,uint256 value);

    //构造函数初始化代币总量，并发送到部署者
    constructor(uint256 _totalSupply){
        totalSupply = _totalSupply * 10 ** uint256(decimals);
        balances[msg.sender] = totalSupply;
        owner = msg.sender;
    }
    // 余额查询
    function balanceOf(address _account) public view returns(uint256){
        return balances[_account];
    }
    // 转账
    function transfer(address _to,uint256 _amount)public returns (bool _success){
        // 判断地址是否正常
        require(address(0)!=_to,"to Address is zero");
        // 交验发起转账人的余额是否充足
        require(balances[msg.sender]>=_amount,"Insuficient balance");

        balances[msg.sender]-=_amount;
        balances[_to]+= _amount;
        //发送转账事件
        emit Transfer(msg.sender, _to, _amount);
        return true;
    }

    // 授权approve 和代扣转账 transferFrom
    function approve(address _spender,uint256 _value)public returns(bool){
        // 判断地址正确性
        require(address(0)!=_spender,"Address invalid");
        // 进行授权额度
        allowance[msg.sender][_spender]=_value;
        // 发送授权事件
        emit Approval(msg.sender, _spender, _value);
        return true;
    }

    // 被授权人操作转账
    function transferFrom(address _from,address _to,uint256 _amount)public returns(bool){
        // 验证地址正确性
        require(address(0)!=_from,"invalid address");
        require(address(0)!=_to,"invalid address");
        // 判断授权额度
        require(allowance[_from][msg.sender]>=_amount,"Insufficient allowance");
        // 判断余额是否充足
        require(balances[_from]>=_amount,"Insufficient balance");

        balances[_from]-=_amount;
        balances[_to]+= _amount;
        allowance[_from][msg.sender] -= _amount;// 削减授权额度。

        emit Transfer(_from, _to, _amount);

        return true;
    }

    // 合约所有者增发
    function mint(uint256 _amount) public returns(bool){
        require(owner==msg.sender,"mint not allow others");
        
        balances[owner]+= _amount;
        totalSupply+= _amount;
        
        emit Transfer(address(0), owner, _amount);
        return true;

    }

}