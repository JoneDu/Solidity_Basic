// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//在一个有序数组中查找目标值。
contract BinarySearch{

    function binarySearch(int256[] memory arr,int256 targetValue) public pure returns (int256){
        // 判断元素个数大于等于2
        require(arr.length>0,unicode"元素个数不满足");
        
        uint256 left = 0;
        uint256 right = arr.length;
        while (left<right) {
            uint256 mid = (left+right)/2;
            if (arr[mid] == targetValue) {
                return int256(mid);
            }else if (arr[mid] > targetValue) {
                right = mid;
            }else{
                left = mid + 1;
            }
        }
        return -1;
    }
}