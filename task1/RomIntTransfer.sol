// SPDX-License-Identifier: MIT
pragma solidity ^0.8;

contract RomIntTransfer {
    //给出一个map ，对应了罗马字符和数字的mapping映射
    mapping(bytes1 => int256) private romIntMap;

    struct RomanNumeral {
        uint256 value;
        string symbol;
    }

    RomanNumeral[] private romanNumerals;

    constructor() {
        romIntMap["I"] = 1;
        romIntMap["V"] = 5;
        romIntMap["X"] = 10;
        romIntMap["L"] = 50;
        romIntMap["C"] = 100;
        romIntMap["D"] = 500;
        romIntMap["M"] = 1000;

        romanNumerals.push(RomanNumeral(1000, "M"));
        romanNumerals.push(RomanNumeral(900, "CM"));
        romanNumerals.push(RomanNumeral(500, "D"));
        romanNumerals.push(RomanNumeral(400, "CD"));
        romanNumerals.push(RomanNumeral(100, "C"));
        romanNumerals.push(RomanNumeral(90, "XC"));
        romanNumerals.push(RomanNumeral(50, "L"));
        romanNumerals.push(RomanNumeral(40, "XL"));
        romanNumerals.push(RomanNumeral(10, "X"));
        romanNumerals.push(RomanNumeral(9, "IX"));
        romanNumerals.push(RomanNumeral(5, "V"));
        romanNumerals.push(RomanNumeral(4, "IV"));
        romanNumerals.push(RomanNumeral(1, "I"));
    }

    function romToInt(string memory _input) public view returns (int256) {
        bytes memory romBytes = bytes(_input);
        uint256 length = romBytes.length;
        require(length >= 1 && length <= 15, unicode"罗马数字长度不合法");
        int256 result;
        for (uint256 i = 0; i < romBytes.length; i++) {
            int256 current = romIntMap[romBytes[i]];
            require(current != 0, unicode"字符错误哦");
            if (
                i == romBytes.length - 1 ||
                current >= romIntMap[romBytes[i + 1]]
            ) {
                result += current;
            } else {
                result -= current;
            }
        }
        return result;
    }

    function intToRom(uint256 num) public view returns (string memory) {
        require(num >= 1 && num <= 3999, unicode"数字不合法");

        string memory result;
        uint256 remaining = num;

        for (uint256 i=0; i<romanNumerals.length; i++) {
            while(remaining >= romanNumerals[i].value) {
                result = string(abi.encodePacked(result,romanNumerals[i].symbol));
                remaining -= romanNumerals[i].value;
            }
        }

        return result;

    }
}
