// SPDX-License-Identifier: MIT
// FennecTechnology Contracts (version v0.1) (test/FennecICO.t.sol)

pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import { FennecCoin } from "./helpers/FennecCoin.sol";
import { PriceFeed } from "./helpers/PriceFeed.sol";
import "./helpers/Addresses.sol";

/// @notice Contract for tests
contract SwapICOTest is Test {
    /// @return 'contract addresses'
    FennecCoin public fennecCoin;
    PriceFeed public priceFeed;

    /// @dev 'Deploy priceFeed and FennecCoin contract'
    function setUp() public {
        priceFeed = new PriceFeed();
        fennecCoin = new FennecCoin(address(priceFeed));
    }

    /// @dev buy FennecCoin
    function testBuy() public {
        vm.startPrank(BUYER);
        address fennecICO = address(fennecCoin.fennecICO());
        (bool success,) = fennecICO.call{value: 1 ether}("");
        require(success);
        require(fennecCoin.balanceOf(BUYER) > 0, "Zero balance");
        vm.stopPrank();
    }

    /// @dev buying all tokens with exceeded msg.value, 1000000 FennecCoin ~ 606 ether
    function testBuyAllToken() public {
        vm.startPrank(BUYER);
        address fennecICO = address(fennecCoin.fennecICO());
        uint256 balanceBefore = BUYER.balance; // 10000 ether
        (bool success,) = fennecICO.call{value: balanceBefore}("");
        uint256 balanceAfter = BUYER.balance;
        require(success);
        require(balanceBefore - balanceAfter < 607 ether);
        vm.stopPrank();
    }

    /// @dev try to buying FennecCoin, when token sale ended
    function testFaildBuy() public {
        testBuyAllToken();

        testBuy();
    }

    receive() external payable {
    }
}