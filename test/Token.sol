// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "@openzeppelin/token/ERC20/ERC20.sol";

contract Token is ERC20 {
    constructor(string memory name,string memory symbol) ERC20(name, symbol) {
        _mint(msg.sender, 21000000 * 10 ** decimals());
    }
}