// SPDX-License-Identifier: MIT
// FennecTechnology Contracts (version v0.1) (token/FennecCoin.sol)

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract FennecCoin is ERC20 {

    constructor() ERC20("FennecCoin", "Fennec") {
    }
        
    receive () external payable {        
    }
}