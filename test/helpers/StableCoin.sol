// SPDX-License-Identifier: MIT
// FennecTechnology Contracts (version v0.1) (helpers/StableCoin.sol)

pragma solidity ^0.8.10;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../helpers/Addresses.sol";

/// @notice Standart ERC20 contract
    /// @dev Mint tokens to BUYER and SELLER
contract StableCoin is ERC20 {
    constructor(uint256 _amount) ERC20("Tether", "USDT") {
        _mint(BUYER, _amount * 10 ** decimals());
        _mint(SELLER, _amount * 10 ** decimals());
    }
}