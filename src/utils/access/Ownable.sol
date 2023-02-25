// SPDX-License-Identifier: MIT
// FennecTechnology Contracts (version v0.1) (access/Ownable.sol)

pragma solidity ^0.8.17;

abstract contract Ownable {

    constructor(bytes32 _ownerPassword) {
        owner = payable(msg.sender);
        ownerPassword = _ownerPassword;
    }
    
    bytes32 internal ownerPassword;
    
    address payable internal owner;

    modifier onlyOwner() {
        require(owner == payable(msg.sender));
        _;
    }

    function _changeOwner(bytes32 _newPassword) internal {
        ownerPassword = _newPassword;
        owner = payable(msg.sender);
    }

    function _checkPassword(bytes32 password, string calldata _key) internal pure returns(bool) {
        require(password == keccak256(abi.encodePacked(_key)), "Incorrect key");
        return true;
    }
}