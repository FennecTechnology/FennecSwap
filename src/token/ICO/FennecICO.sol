// SPDX-License-Identifier: MIT
// FennecTechnology Contracts (version v0.1) (ICO/FennecICO.sol)

pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

/// @title FennecICO
    /// @author 'FennecTechnology'
    /// @notice Contract for ICO (token sale FennecCoin).
    /// @dev Contract uses "chainlink" price feed contracts to determine the price of ETH, BNB and MATIC.

contract FennecICO {
    /// @return 'Price Feed Contract Addresses':
        /// @dev 
            /// Network: Binance Smart Chain
                /// Link - https://data.chain.link/bsc/mainnet/crypto-usd/bnb-usd
                /// address - 0x0567F2323251f0Aab15c8dFb1967E4e8A7D42aeE;
            /// Network: Polygon
                /// Link - https://data.chain.link/polygon/mainnet/crypto-usd/matic-usd
                /// address - 0xAB594600376Ec9fD91F8e885dADF0CE036862dE0;
            /// Network: Optimism
                /// Link - https://data.chain.link/optimism/mainnet/crypto-usd/eth-usd
                /// address - 0x13e3Ee699D1909E989722E753853AE30b17e08c5.
        
    address public immutable priceFeed;

    address payable private immutable owner;
    address public immutable fennecCoin;
    
    constructor(address _priceFeed, address _owner) {
        owner = payable(_owner);
        fennecCoin = msg.sender;
        priceFeed = _priceFeed;
    }

    /// @dev Get price ETH, BNB or MATIC in USD from priceFeed contract.
    function _getPrice() view internal returns(int) {
        return AggregatorInterface(priceFeed).latestAnswer();
    }

    /// @dev Buying fennecCoin, price ~ 1 USD.
    receive () external payable {   
        uint balance = IERC20(fennecCoin).balanceOf(address(this));
        require(balance > 0, "Tokens are over");
        int latestAnswer = _getPrice();
        require (latestAnswer > 0, "Error");
        uint amount = msg.value * uint(latestAnswer) / 10 ** AggregatorV3Interface(priceFeed).decimals();
        
        if (amount <= balance) {
            owner.transfer(msg.value);
            IERC20(fennecCoin).transfer(msg.sender, amount);
        }
        else {
            owner.transfer(msg.value * balance / amount);
            IERC20(fennecCoin).transfer(msg.sender, balance);
            payable(msg.sender).transfer(msg.value * (amount - balance) / amount);
        }        
    }
}