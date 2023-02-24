// SPDX-License-Identifier: MIT
// FennecTechnology Contracts (version v0.1) (test/FennecSwap.t.sol)

pragma solidity ^0.8.10;

import "forge-std/Test.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { FennecSwap } from "../src/FennecSwap.sol";
import { FennecCoin } from "./helpers/FennecCoin.sol";
import { PriceFeed } from "./helpers/PriceFeed.sol";
import { StableCoin } from "./helpers/StableCoin.sol";
import "./helpers/Addresses.sol";

string constant TOKEN = "USDT";
bytes32 constant OWNER_PASSWORD = 0x7624778dedc75f8b322b9fa1632a610d40b85e106c7d9bf0e743a9ce291b9c6f;
bytes32 constant PASSWORD = 0x1c8aff950685c2ed4bc3174f3472287b56d9517b9c948127319a09a7a36deac8; // "hello"
uint256 constant AMOUNT = 1e18;
string constant PRICE = "74 RUB";
uint256 constant MIN_DEP_USD = 100; // 100 USD - for example

/// @notice Contract for tests
contract FennecSwapTest is Test {
    /// @return 'contract addresses'
    FennecSwap public fennecSwap;
    IERC20 public stableCoin;

    ////////////////////////////////////////SET_UP_TEST/////////////////////////////////////////////

    /// @dev Deploy stableCoin, FennecSwap and priceFeed contracts;
    /// @dev add stableCoin on FennecSwap contract;
    /// @dev set minimal deposit on FennecSwap contract.
    
    function setUp() public {
        /// @dev main network simulation and setting variables
        vm.startPrank(OWNER, OWNER);
        PriceFeed priceFeed = new PriceFeed();
        FennecCoin fennecCoin = new FennecCoin();
        fennecSwap = new FennecSwap(payable(address(fennecCoin)), OWNER_PASSWORD, address(priceFeed), ADMIN);
        stableCoin = new StableCoin(1000);
        addToken(stableCoin);
        minimalDeposit(MIN_DEP_USD);
        vm.stopPrank();        
        
        /// @dev get signature from telegram bot (ADMIN) for registration users
        bytes32 messageBuyer = getHash(BUYER, "laches1", "@laches1");
        bytes32 messageSeller = getHash(SELLER, "alex", "@alex");
        bytes memory sigForBuyer = getSig(messageBuyer);
        bytes memory sigForSeller = getSig(messageSeller);
        
        /// @dev registration BUYER and SELLER
        vm.startPrank(BUYER, BUYER);
        fennecSwap.registration("laches1", "@laches1", sigForBuyer);
        vm.stopPrank();
        vm.startPrank(SELLER, SELLER);
        fennecSwap.registration("alex", "@alex", sigForSeller);
        vm.stopPrank();
    }   

    /////////////////////////////////////SERVICE_FUNCTION/////////////////////////////////////////

    function withPrefix(bytes32 hash) private pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                hash
            )
        );
    }

    function getHash(address user, string memory userName, string memory telegram) private pure returns(bytes32) {
        bytes32 message = withPrefix(keccak256(abi.encodePacked(
            user,
            userName,
            telegram
        )));

        return message;
    }

    function getSig(bytes32 message) private pure returns(bytes memory) {
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(ADMIN_PRIVATE_KEY, message);
        return bytes(abi.encodePacked(r, s, v));
    }

    /// @dev 'Add stablecoin from owner account'
    function addToken(IERC20 _stableCoin) private {
        fennecSwap.addToken(_stableCoin);
    }

    /// @dev 'Set minimal deposit'
    function minimalDeposit(uint amount) private {
        fennecSwap.setMinDeposit(amount);
    }

    /////////////////////////////////////////TESTS/////////////////////////////////////////////////

    /// @dev try to register from another address
    function testFaildReg() public {
        bytes32 message = getHash(BUYER, "alex", "@alex");
        bytes memory signature = getSig(message);

        vm.startPrank(PRANKER, PRANKER);
        fennecSwap.registration("alex", "@alex", signature);
        vm.stopPrank();
    }

    /// @dev try to register with another username and telegram account
    function testFaildReg2() public {
        bytes32 message = getHash(BUYER, "alex", "@alex");
        bytes memory signature = getSig(message);

        vm.startPrank(BUYER, BUYER);
        fennecSwap.registration("pranker", "@pranker", signature);
        vm.stopPrank();
    }

    /// @dev try to register on behalf of the contract (checking the modifier onlyEOA)
    function testFaildReg3() public {
        address thisContract = address(this);
        bytes32 message = getHash(thisContract, "contract", "@contract");
        bytes memory signature = getSig(message);

        vm.startPrank(thisContract, thisContract);
        fennecSwap.registration("contract", "@contract", signature);
        vm.stopPrank();
    }


    /// @dev 'place buying order'
    function testBuy() public {
        uint256 deposit = fennecSwap.minDeposit();

        vm.startPrank(BUYER, BUYER);
        fennecSwap.buy{value: deposit}(TOKEN, PASSWORD, AMOUNT, PRICE);
        vm.stopPrank();
    }

    /// @dev 'try to place order with less deposit'
    function testFaildBuy() public {
        uint256 deposit = fennecSwap.minDeposit();

        vm.startPrank(BUYER, BUYER);
        fennecSwap.buy{value: deposit - 1}(TOKEN, PASSWORD, AMOUNT, PRICE);
        vm.stopPrank();
    }

    /// @dev 'try to place an order without being a user'
    function testFaildBuy2() public {
        uint256 deposit = fennecSwap.minDeposit();

        vm.startPrank(PRANKER, PRANKER);
        fennecSwap.buy{value: deposit}(TOKEN, PASSWORD, AMOUNT, PRICE);
        vm.stopPrank();
    }

    /// @dev 'place selling order'
    function testSell() public {
        uint deposit = fennecSwap.minDeposit();

        vm.startPrank(SELLER, SELLER);        
        stableCoin.approve(address(fennecSwap), AMOUNT);
        fennecSwap.sell{value: deposit}(TOKEN, PASSWORD, AMOUNT, PRICE);
        vm.stopPrank();
    }

    /// @dev 'try to place selling order with insufficient tokens on the balance'
    function testFaildSell() public {        
        uint256 deposit = fennecSwap.minDeposit();

        vm.startPrank(SELLER, SELLER);
        stableCoin.approve(address(fennecSwap), AMOUNT);
        fennecSwap.sell{value: deposit}(TOKEN, PASSWORD, 10000e18, PRICE);
        vm.stopPrank();
    }

    /// @dev 'approve the order on behalf of the seller'
    function testApprove() public {
        uint deposit = fennecSwap.minDeposit();
        
        testBuy();

        vm.startPrank(SELLER, SELLER);
        stableCoin.approve(address(fennecSwap), AMOUNT);
        fennecSwap.approve{value: deposit}(1, "hello");
        vm.stopPrank();
    }

    /// @dev 'try to approve non-existent order'
    function testFaildApprove() public {
        uint deposit = fennecSwap.minDeposit();

        testBuy();

        vm.startPrank(SELLER, SELLER);
        stableCoin.approve(address(fennecSwap), AMOUNT);
        fennecSwap.approve{value: deposit}(2, "hello");
        vm.stopPrank();
    }

    /// @dev 'try to approve order with incorrect password'
    function testFaildApprove2() public {
        uint deposit = fennecSwap.minDeposit();

        testBuy();

        vm.startPrank(SELLER, SELLER);
        stableCoin.approve(address(fennecSwap), AMOUNT);
        fennecSwap.approve{value: deposit}(1, "hi");
        vm.stopPrank();
    }

    /// @dev 'try to approve own order'
    function testFaildApprove3() public {
        uint deposit = fennecSwap.minDeposit();

        testBuy();

        vm.startPrank(BUYER, BUYER);
        stableCoin.approve(address(fennecSwap), AMOUNT);
        fennecSwap.approve{value: deposit}(1, "hello");
        vm.stopPrank();
    }

    /// @dev 'try to approve approved order'
    function testFaildApprove4() public {
        uint deposit = fennecSwap.minDeposit();
        
        testApprove();

        vm.startPrank(SELLER, SELLER);
        stableCoin.approve(address(fennecSwap), AMOUNT);
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

    // function testGas() public view {
    //     console.logBytes();
    // }
}