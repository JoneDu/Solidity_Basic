// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract RomIntTransfer{

    //给出一个map ，对应了罗马字符和数字的mapping映射
    mapping(bytes1=>int256) private romIntMap;

    constructor (){
        romIntMap["I"] = 1;
        romIntMap["V"] = 5;
        romIntMap["X"] = 10;
        romIntMap["L"] = 50;
        romIntMap["C"] = 100;
        romIntMap["D"] = 500;
        romIntMap["M"] = 1000;
    }

    function romToInt(string memory _input) public view returns (int256){
        bytes memory romBytes = bytes(_input);
        uint length = romBytes.length;
        require(length>=1 && length<=15,unicode"罗马数字长度不合法");
        int256 result;
        for (uint i=0;i< romBytes.length;i++) {
            int256 current = romIntMap[romBytes[i]];
            require(current!=0,unicode"字符错误哦");
            if (i== romBytes.length-1 || current>=romIntMap[romBytes[i+1]]){
                result += current;
            }else{
                result -= current;    
            }
        }
        return result;
    }

}