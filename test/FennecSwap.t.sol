// SPDX-License-Identifier: MIT
// FennecTechnology Contracts (version v0.1) (test/FennecSwap.t.sol)

pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { FennecSwap } from "../src/FennecSwap.sol";
import { FennecCoin } from "../src/token/FennecCoin.sol";
import { PriceFeed } from "./helpers/PriceFeed.sol";
import { StableCoin } from "./helpers/StableCoin.sol";
import "./helpers/Addresses.sol";

string constant token = "USDT";
bytes32 constant password = 0x1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8; // "hello"
uint256 constant amount = 1e18;
string constant price = "74 RUB";

/// @notice Contract for tests
contract FennecSwapTest is Test {
    /// @return 'contract addresses'
    FennecCoin public fennec;
    PriceFeed public priceFeed;
    FennecSwap public fennecSwap;
    IERC20 public stableCoin;

    /// @dev Deploy stableCoin, FennecSwap and priceFeed contracts;
    /// @dev add stableCoin on FennecSwap contract;
    /// @dev set minimal deposit on FennecSwap contract.
    function setUp() public {

        /// @dev main network simulation and setting variables
        /////////////////////////////////////////////////////////////////////////////////////////////
        priceFeed = new PriceFeed();
        fennec = new FennecCoin(address(priceFeed));
        fennecSwap = new FennecSwap(payable(address(fennec)), 0x7624778dedc75f8b322b9fa1632a610d40b85e106c7d9bf0e743a9ce291b9c6f, address(priceFeed), ADMIN);
        stableCoin = new StableCoin(1000);
        addToken();
        minimalDeposit();
        
        /// @dev get signature from telegram bot (ADMIN) for registration users
        /////////////////////////////////////////////////////////////////////////////////////////////
        bytes32 message1 = withPrefix(keccak256(abi.encodePacked(
            BUYER,
            "laches1",
            "@laches1"
        )));

        bytes32 message2 = withPrefix(keccak256(abi.encodePacked(
            SELLER,
            "alex",
            "@alex"
        )));

        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(ADMIN_PRIVATE_KEY, message1);
        (uint8 v2, bytes32 r2, bytes32 s2) = vm.sign(ADMIN_PRIVATE_KEY, message2);

        bytes memory signature1 = bytes(abi.encodePacked(r1, s1, v1));
        bytes memory signature2 = bytes(abi.encodePacked(r2, s2, v2));

        /// @dev registration BUYER and SELLER
        /////////////////////////////////////////////////////////////////////////////////////////////
        vm.startPrank(BUYER, BUYER);        
        fennecSwap.registration("laches1", "@laches1", signature1);
        vm.stopPrank();

        vm.startPrank(SELLER, SELLER);
        fennecSwap.registration("alex", "@alex", signature2);
        vm.stopPrank();
    }

    /// @dev service function
    function withPrefix(bytes32 hash) private pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                hash
            )
        );
    }

    /// @dev 'Add stablecoin from owner account'
    function addToken() internal {
        fennecSwap.addToken(stableCoin);
    }

    /// @dev 'Set minimal deposit 100 USD for example'
    function minimalDeposit() internal {
        fennecSwap.setMinDeposit(100);
    }

    /// @dev try to registration from another address
    function testFaildReg() public {
        bytes32 message = withPrefix(keccak256(abi.encodePacked(
            PRANKER,
            "pranker666",
            "@pranker666"
        )));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ADMIN_PRIVATE_KEY, message);

        bytes memory signature = bytes(abi.encodePacked(r, s, v));

        vm.startPrank(BUYER, BUYER);
        fennecSwap.registration("pranker666", "@pranker666", signature);
        vm.stopPrank();
    }

    /// @dev try to registration with another username or telegram account
    function testFaildReg2() public {
        bytes32 message = withPrefix(keccak256(abi.encodePacked(
            PRANKER,
            "pranker666",
            "@pranker666"
        )));

        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ADMIN_PRIVATE_KEY, message);

        bytes memory signature = bytes(abi.encodePacked(r, s, v));

        vm.startPrank(PRANKER, PRANKER);
        fennecSwap.registration("pranker", "@pranker", signature);
        vm.stopPrank();
    }

    /// @dev 'place buying order'
    function testBuy() public {
        vm.startPrank(BUYER, BUYER);
        uint256 deposit = fennecSwap.minDeposit();
        fennecSwap.buy{value: deposit}(token, password, amount, price);
        vm.stopPrank();
    }

    /// @dev 'try to place order with less deposit'
    function testFaildBuy() public {
        uint256 deposit = fennecSwap.minDeposit();

        vm.startPrank(BUYER, BUYER);
        fennecSwap.buy{value: deposit - 1}(token, password, amount, price);
        vm.stopPrank();
    }

    /// @dev 'try to place an order without being a user'
    function testFaildBuy2() public {
        uint256 deposit = fennecSwap.minDeposit();

        vm.startPrank(PRANKER, PRANKER);
        fennecSwap.buy{value: deposit}(token, password, amount, price);
        vm.stopPrank();
    }

    /// @dev 'place selling order'
    function testSell() public {
        uint deposit = fennecSwap.minDeposit();

        vm.startPrank(SELLER, SELLER);        
        stableCoin.approve(address(fennecSwap), amount);
        fennecSwap.sell{value: deposit}(token, password, amount, price);
        vm.stopPrank();
    }

    /// @dev 'try to place selling order with insufficient tokens on the balance'
    function testFaildSell() public {
        vm.startPrank(SELLER, SELLER);        
        uint256 deposit = fennecSwap.minDeposit();
        stableCoin.approve(address(fennecSwap), amount);
        fennecSwap.sell{value: deposit}(token, password, 10000e18, price);
        vm.stopPrank();
    }

    /// @dev 'approve the order on behalf of the seller'
    function testApprove() public {
        testBuy();

        vm.startPrank(SELLER, SELLER);
        uint deposit = fennecSwap.minDeposit();
        stableCoin.approve(address(fennecSwap), amount);
        fennecSwap.approve{value: deposit}(1, "hello");
        vm.stopPrank();
    }

    /// @dev 'try to approve non-existent order'
    function testFaildApprove() public {
        testBuy();

        vm.startPrank(SELLER, SELLER);
        uint deposit = fennecSwap.minDeposit();
        stableCoin.approve(address(fennecSwap), amount);
        fennecSwap.approve{value: deposit}(2, "hello");
        vm.stopPrank();
    }

    /// @dev 'try to approve order with incorrect password'
    function testFaildApprove2() public {
        testBuy();

        vm.startPrank(SELLER, SELLER);
        uint deposit = fennecSwap.minDeposit();
        stableCoin.approve(address(fennecSwap), amount);
        fennecSwap.approve{value: deposit}(1, "hi");
        vm.stopPrank();
    }

    /// @dev 'try to approve own order'
    function testFaildApprove3() public {
        testBuy();

        vm.startPrank(BUYER, BUYER);
        uint deposit = fennecSwap.minDeposit();
        stableCoin.approve(address(fennecSwap), amount);
        fennecSwap.approve{value: deposit}(1, "hello");
        vm.stopPrank();
    }

    /// @dev 'try to approve approved order'
    function testFaildApprove4() public {
        testBuy();
        testApprove();

        vm.startPrank(SELLER, SELLER);
        uint deposit = fennecSwap.minDeposit();
        stableCoin.approve(address(fennecSwap), amount);
        fennecSwap.approve{value: deposit}(1, "hello");
        vm.stopPrank();
    }

    /// @dev 'exchange and complete the order on behalf of the seller'
    function testExchange() public {
        testApprove();

        vm.startPrank(SELLER, SELLER);
        fennecSwap.exchange(1);
        vm.stopPrank();
    }

    /// @dev 'try to exchange and complete the order on behalf of the buyer'
    function testFaildExchange() public {
        testApprove();

        vm.startPrank(BUYER, BUYER);
        fennecSwap.exchange(1);
        vm.stopPrank();
    }

    /// @dev 'try to complete the order twice'
    function testFaildExchange2() public {
        testExchange();

        vm.startPrank(SELLER, SELLER);
        fennecSwap.exchange(1);
        vm.stopPrank();
    }

    /// @dev 'cancel the order on behalf of the author'
    function testCancel() public {
        testBuy();

        vm.startPrank(BUYER, BUYER);
        fennecSwap.cancel(1);
        vm.stopPrank();
    }

    /// @dev 'try to cancel the order on someone else's behalf'
    function testFaildCancel() public {
        testBuy();

        vm.startPrank(SELLER, SELLER);
        fennecSwap.cancel(1);
        vm.stopPrank();
    }

    /// @dev 'try to cancel the approved order'
    function testFaildCancel2() public {
        testApprove();

        vm.startPrank(BUYER, BUYER);
        fennecSwap.cancel(1);
        vm.stopPrank();
    }

    /// @dev 'try to cancel the completed order'
    function testFaildCancel3() public {
        testExchange();

        vm.startPrank(BUYER, BUYER);
        fennecSwap.cancel(1);
        vm.stopPrank();
    }

    receive() external payable {
    }
}