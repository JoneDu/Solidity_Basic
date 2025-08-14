// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//题目描述：将两个有序数组合并为一个有序数组
contract MergeArr{

    function mergeSortedArr(int256[] calldata arr1,int256[] calldata arr2)public pure returns (int256[] memory){

        uint l1 = arr1.length;
        uint l2 = arr2.length;
        int256[] memory resultArr = new int256[](l1+l2);
        // 定义三个游标
        uint i = 0;
        uint j = 0;
        uint k = 0;
        while(i<l1 && j<l2){
            if(arr1[i]<arr2[j]){
                resultArr[k++] = arr1[i++];
            }else{
                resultArr[k++] = arr2[j++];
            }
        }

        // 兜底判断没有判断完的数组
        while(i<l1){
            resultArr[k++]=arr1[i++];
        }
        while(j<l2){
            resultArr[k++]=arr2[j++];
        }
        return resultArr;
    }

}