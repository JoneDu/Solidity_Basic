// SPDX-License-Identifier: MIT
// Compatible with OpenZeppelin Contracts ^5.4.0
pragma solidity ^0.8.27;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20Permit} from "@openzeppelin/contracts/token/ERC20/extensions/ERC20Permit.sol";

contract ZiERC20Token is ERC20, ERC20Permit {
    constructor() ERC20("ZiERC20Token", "MTK") ERC20Permit("ZiERC20Token") {
        // 给部署者铸造 20000枚.
        _mint(msg.sender,20000 * 10 ** 18);
    }
}