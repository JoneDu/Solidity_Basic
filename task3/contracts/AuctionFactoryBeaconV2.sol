// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.0;
import "./AuctionFactoryBeacon.sol";
contract AuctionFactoryBeaconV2 is AuctionFactoryBeacon{
    string public constant testName="2.0";
    function getTestName() public view returns (string memory){
        return testName;
    }
}
