// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

//✅ 反转字符串 (Reverse String)
// 题目描述：反转一个字符串。输入 "abcde"，输出 "edcba"

contract ReverseStr{

    function reverserStr(string calldata s) public pure returns(string memory){
        bytes memory sBytes = bytes(s);
        for (uint i = 0;i<sBytes.length/2;i++){
            (sBytes[i],sBytes[sBytes.length-1-i])=(sBytes[sBytes.length-1-i],sBytes[i]);
        }
        return string(sBytes);
    }
}