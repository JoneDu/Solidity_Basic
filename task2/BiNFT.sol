// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
// 使用标准的ERC721 接口来定制一个自己NFT，允许合约拥有者mint token
contract BiNFT is ERC721URIStorage, Ownable{
    uint256 public tokenCounter;

    constructor() 
    ERC721("BiNFT","BNFT") 
    Ownable(msg.sender){
        tokenCounter = 0;
    }
    
    function mint(address recipient,string memory tokenURI) public onlyOwner returns(uint256 tokenId){
        tokenId = tokenCounter;
        tokenCounter+=1;
        _safeMint(recipient, tokenId);
        _setTokenURI(tokenId,tokenURI);
        return tokenId;
    }
}