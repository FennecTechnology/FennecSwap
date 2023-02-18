// SPDX-License-Identifier: MIT
// FennecTechnology Contracts (version v0.1) (helpers/PriceFeed.sol)

pragma solidity ^0.8.10;

/// @notice Price Feed Contract
contract PriceFeed {
    /// @return 'ETH/USD'
    int public latestAnswer = 164910143001;

    uint8 public decimals = 8;
}