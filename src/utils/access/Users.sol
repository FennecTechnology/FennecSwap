// SPDX-License-Identifier: MIT
// FennecTechnology Contracts (version v0.1) (access/Users.sol)

pragma solidity ^0.8.17;

abstract contract Users {
    string constant ADMIN = unicode"👮";
    string constant BANNED = unicode"🔒";

    constructor() {
        _reservedName[ADMIN] = true;
        _reservedName[BANNED] = true;
    }

    /// @dev Struct for user information
    struct User {
        string username;
        string telegram;
        uint256 completedOrders;
    }
    
    mapping(address => User) internal _userInfo;
    mapping(string => bool) internal _reservedName;

    modifier onlyUsers {
        require(_checkUser(), "You are banned!");
        require(bytes(_userInfo[msg.sender].telegram).length != 0, "You are not user");
        _;
    }
    
    /// @dev service function for registration
    function _registration(string calldata _username, string calldata _telegram, bytes calldata signature) internal {
        require(_checkUser(), "You are banned!");
        require(bytes(_userInfo[msg.sender].username).length == 0, "You are user");        
        require(!_reservedName[_username], "Username is not available");

        bytes32 message = _withPrefix(keccak256(abi.encodePacked(
            msg.sender,
            _username,
            _telegram
        )));

        address recoverSigner = _recoverSigner(message, signature);
        bytes32 hashSigner = keccak256(abi.encodePacked(_userInfo[recoverSigner].username));
        bytes32 hashAdmin = keccak256(abi.encodePacked(ADMIN));

        require(hashSigner == hashAdmin, "invalid sig!");

        _userInfo[msg.sender].username = _username;
        _userInfo[msg.sender].telegram = _telegram;
        _reservedName[_username] = true;
    }

    /// @dev service functions:

    function _recoverSigner(bytes32 message, bytes calldata signature) private pure returns(address) {
        (uint8 v, bytes32 r, bytes32 s) = _splitSignature(signature);

        return ecrecover(message, v, r, s);
    }

    function _splitSignature(bytes memory signature) private pure returns(uint8 v, bytes32 r, bytes32 s) {
        require(signature.length == 65);

        assembly {
            r := mload(add(signature, 32))

            s := mload(add(signature, 64))

            v := byte(0, mload(add(signature, 96)))
        }

        return(v, r, s);
    }

    function _withPrefix(bytes32 hash) private pure returns(bytes32) {
        return keccak256(
            abi.encodePacked(
                "\x19Ethereum Signed Message:\n32",
                hash
            )
        );
    }

    function _addAdmin(address _admin) internal {
        require(keccak256(abi.encodePacked(_userInfo[_admin].username)) != keccak256(abi.encodePacked(ADMIN)), "This address is admin");
        _userInfo[_admin].username = ADMIN;
    }

    function _ban(address _user) internal {
        _reservedName[_userInfo[_user].username] = false;
        _userInfo[_user].username = BANNED;
    }

    function _checkUser() internal view returns(bool) {
        return keccak256(abi.encodePacked(_userInfo[msg.sender].username)) != keccak256(abi.encodePacked(BANNED));
    }

    function _removeStatus(address _user) internal {
        bytes32 userHash = keccak256(abi.encodePacked(_userInfo[_user].username));
        if (userHash == keccak256(abi.encodePacked(BANNED)) ||
            userHash == keccak256(abi.encodePacked(ADMIN))) {
            delete _userInfo[_user].username;
        } else {
            revert();
        }
    }
}