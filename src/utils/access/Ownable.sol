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

    function _changeOwner(string calldata _password, bytes32 _newPassword) internal {
        require(_checkPassword(_password, _newPassword));

        ownerPassword = _newPassword;
        owner = payable(msg.sender);
    }

    function _checkPassword(string calldata _password, bytes32 _newPassword) internal view returns(bool) {
        require(ownerPassword == keccak256(abi.encodePacked(_password)), "Incorrect passwaord");
        require(ownerPassword != _newPassword, "New and current passwords match!");
        return true;
    }
}