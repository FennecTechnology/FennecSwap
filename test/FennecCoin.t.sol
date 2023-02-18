// SPDX-License-Identifier: MIT
// FennecTechnology Contracts (version v0.1) (test/FennecCoin.t.sol)

pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import { FennecCoin } from "../src/token/FennecCoin.sol";
import { PriceFeed } from "./helpers/PriceFeed.sol";
import "./helpers/Addresses.sol";

/// @notice Contract for tests
contract FennecCoinTest is Test {
    /// @return 'contract addresses'
    FennecCoin public fennecCoin;
    PriceFeed public priceFeed;

    /// @dev 'Deploy priceFeed and fennecCoin contract'
    function setUp() public {
        priceFeed = new PriceFeed();
        fennecCoin = new FennecCoin(address(priceFeed));

        /// @dev buy fennecCoin from FennecICO contract
        vm.startPrank(BUYER, BUYER);
        address fennecCoinICO = address(fennecCoin.fennecICO());
        (bool success,) = fennecCoinICO.call{value: 1 ether}("");
        require(success);
        vm.stopPrank();
    }

    /// @dev 'buy fennecCoin and stake'
    function testStake() public {
        vm.startPrank(BUYER, BUYER);
        uint256 balance = fennecCoin.balanceOf(BUYER);

        if (balance == 0) {
            revert();
        } else {
            fennecCoin.increaseStake(balance);
        }

        assertEq(fennecCoin.totalStake(), balance);
        assertEq(fennecCoin.balanceOf(address(this)), 0);
        vm.stopPrank();
    }

    /// @dev 'try to stake fennecCoin with zero balance'
    function testFaildStake() public {
        vm.startPrank(PRANKER, PRANKER);
        fennecCoin.increaseStake(1e18);
        vm.stopPrank();
    }

    /// @dev 'try to stake fennecCoin attempt 30 days before payout date'
    function testFaildStake2() public {
        vm.startPrank(BUYER, BUYER);
        uint256 balance = fennecCoin.balanceOf(BUYER);
        fennecCoin.increaseStake(balance / 3);
        vm.warp(fennecCoin.payoutDate() - 30 days);
        fennecCoin.increaseStake(balance / 3);
        vm.stopPrank();
    }

    /// @dev 'payout dividend'
    function testPayoutDividend() public {
        /// @dev 'take profit from FennecSwap for example'
        (bool success,) = address(fennecCoin).call{value: 1 ether}("");
        require(success);

        /// @dev 'warp timestamp to payoutDate and payout dividend'
        testStake();
        assertEq(BUYER.balance, 9999 ether);
        vm.startPrank(BUYER, BUYER);
        vm.warp(fennecCoin.payoutDate() + 1);
        fennecCoin.payoutDividend();
        assertEq(BUYER.balance, 10000 ether);
        vm.stopPrank();
    }

    /// @dev 'try to payout dividend'
    function testFaildPayout() public {
        /// @dev 'take profit from FennecSwap for example'
        (bool success,) = address(fennecCoin).call{value: 1 ether}(""); 
        require(success);

        /// @dev 'try to payout dividend, 1 day before payoutDate'
        testStake();
        vm.startPrank(BUYER, BUYER);
        vm.warp(fennecCoin.payoutDate() - 1 days);
        fennecCoin.payoutDividend();
        assertEq(BUYER.balance, 10000 ether);
        vm.stopPrank();
    }

    receive() external payable {
    }
}