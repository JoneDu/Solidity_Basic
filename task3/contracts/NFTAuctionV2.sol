// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./NFTAuction.sol";

contract NFTAuctionV2 is NFTAuction {

    string public testName;

    function getAdmin() public view returns (address) {
        return admin;
    }

    function setTestName(string memory _name) public {
        testName = _name;
    }

    function getTestName() public view returns (string memory) {
        return testName;
    }
}