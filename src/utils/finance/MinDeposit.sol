// SPDX-License-Identifier: MIT
// FennecTechnology Contracts (version v0.1) (finance/MinDeposit.sol)

pragma solidity ^0.8.17;

import "@chainlink/contracts/src/v0.8/interfaces/AggregatorInterface.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";

abstract contract MinDeposit {

    constructor(address _priceFeed) {
        priceFeed = _priceFeed;
    }
    
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

    uint256 public minDepositUSD;

    /// @dev Set a minimum deposit in USD.
    function _setMinDeposit(uint _amount) internal {
        minDepositUSD = _amount;
    }

    function _minDeposit() internal view returns(uint256) {
        return _getPrice() * minDepositUSD;
    }

    /// @dev Utility function for calculating the price.
    function _getPrice() internal view returns(uint256) {
        uint8 decimals = AggregatorV3Interface(priceFeed).decimals();
        int latestPrice = AggregatorInterface(priceFeed).latestAnswer();
        uint256 price;
        if (latestPrice > 0) {
            price = (1e18 * 10 ** decimals) / uint256(latestPrice);
        } else {
            revert();
        }
        return price;
    }
}