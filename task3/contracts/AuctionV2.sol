// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;

import "./Auction.sol";

contract AuctionV2 is Auction {

    string public testName;

    string public constant hello = "hello Test!";

    function setTestName(string memory _name) public {
        testName = _name;
    }
}