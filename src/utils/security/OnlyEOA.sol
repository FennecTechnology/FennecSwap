// SPDX-License-Identifier: MIT
// FennecTechnology Contracts (version v0.1) (security/OnlyEOA.sol)

pragma solidity ^0.8.17;

abstract contract OnlyEOA {
    
    modifier onlyEOA() {
        address _msgSender = msg.sender;
        
        require(
            _msgSender == tx.origin &&
            _msgSender.code.length == 0 && 
            _msgSender.balance > 1 wei,
            "Sender is a contract"
        );
        _;
    }
}