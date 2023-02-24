// SPDX-License-Identifier: MIT
// FennecTechnology Contracts (version v0.1) (src/FennecSwap.sol)

pragma solidity ^0.8.17;

import "./utils/access/Ownable.sol";
import "./utils/access/Users.sol";
import "./utils/finance/MinDeposit.sol";
import "./utils/security/OnlyEOA.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/IERC20Metadata.sol";

/// @title FennecSwap
    /// @author 'FennecTechnology'
    /// @notice Contract for P2P exchange between users.
    /// @dev The basic principle of trust is based on freezing the deposits of both parties to the transaction.
    /// @dev Contract uses "chainlink" price feed contracts to determine the price of ETH, BNB and MATIC.

contract FennecSwap is Ownable, Users, MinDeposit, OnlyEOA {
    using SafeERC20 for IERC20;

    /// @return 'Variables in storage'
    address payable public immutable fennecCoin;
    uint256 public totalOrders;
    mapping(string => IERC20) private _addressToken;
    mapping(uint256 => Order) private _orders;

    /// @dev custom errors
    error UnavailableOrder();
    error IncorrectPass();

    /// @dev setting all required variables.
    constructor (address payable _fennecCoin, bytes32 _ownerPassword, address _priceFeed, address _admin)
        Ownable (_ownerPassword)
        MinDeposit (_priceFeed)
        Users(_admin) {
        fennecCoin = _fennecCoin;
    }

    /// Owner functions:
    
    /// @dev The list of stablecoins is limited and only the owner of can add them.
    event newToken(string symbol, address token);

    function addToken(IERC20 _token) external onlyOwner onlyEOA {
        string memory symbol = IERC20Metadata(address(_token)).symbol();
        require(_addressToken[symbol] == IERC20(address(0)), "Token has already been added");
        _addressToken[symbol] = _token;
        emit newToken(symbol, address(_token));
    }

    /// @dev The owner can set a minimum deposit in USD.
    function setMinDeposit(uint _amount) external onlyOwner onlyEOA {
        _setMinDeposit(_amount);
    }

    /// @dev To change the owner of the contract, you must enter an unencrypted password.
    function changeOwner(string calldata _key, bytes32 _newPassword) external onlyEOA {
        require(_checkPassword(ownerPassword, _key));
        require(ownerPassword != _newPassword, "New and current passwords match!");
        
        _changeOwner(_newPassword);
    }

    /// @dev To change the admin, you must enter an unencrypted password.
    function changeAdmin(string calldata _key, bytes32 _newPassword, address _newAdmin) external onlyEOA {
        require(_checkPassword(ownerPassword, _key));
        require(ownerPassword != _newPassword, "New and current passwords match!");
        
        admin = _newAdmin;
        ownerPassword = _newPassword;
    }

    /// Public functions:

    /// @dev Check username
    function checkUsername(string calldata _name) external view returns(bool) {
        return _reservedName[_name];
    }

    /// @dev Simple user registration
    function registration(string calldata _username, string calldata _telegram, bytes calldata signature) external onlyEOA {
        _registration(_username, _telegram, signature);
    }

    /// @dev Viewing information about the user, his contacts and the number of completed orders
    function userInfo(address _user) external view returns(User memory) {
        return _userInfo[_user];
    }

    /// @dev Before placing an order, you need to check the minimum deposit in ETH, BNB or MATIC (depending on network).
    function minDeposit() public view returns(uint256) {
        return _minDeposit();
    }

    /// @dev View addreses of stablecoins.
    function addressToken(string calldata _symbol) public view returns(IERC20) {
        require(_addressToken[_symbol] != IERC20(address(0)), "This token has not been added");
        return _addressToken[_symbol];
    }

    /// @dev View all orders by number.
    function order(uint256 _number) external view returns(Order memory) {
        require(_orders[_number].buyer != address(0) && _orders[_number].seller != address(0), "Order does not exist");
        return _orders[_number];
    }

    /// Main user functions:

    /// @dev Event when a new order was placed
    event orderPlaced(
        uint256 id,         
        address indexed creator
    );

    struct Order {
        address payable buyer;
        address payable seller;
        string token;
        string price;
        uint256 amount;
        uint256 deposit;
        bytes32 password;
    }

    /// @dev Function to create a buy order.
    function buy(
        string calldata _token, 
        bytes32 _password,
        uint256 _amount,
        string calldata _price
        ) external payable onlyUsers {
            IERC20 token = _addressToken[_token];
            require(address(token) != address(0));
            require(msg.value >= _minDeposit(), "Not enough value");
            require(_password != bytes32(0), "Incorrect password");

            unchecked {
                ++totalOrders;
            }

            _orders[totalOrders].buyer = payable(msg.sender);
            _orders[totalOrders].token = _token;
            _orders[totalOrders].price = _price;
            _orders[totalOrders].amount = _amount;
            _orders[totalOrders].deposit = msg.value;
            _orders[totalOrders].password = _password;
        
            emit orderPlaced(
                totalOrders,
                msg.sender
            );
        }

    /// @dev Function to create a sales order.
    function sell(
        string calldata _token, 
        bytes32 _password, 
        uint256 _amount,
        string calldata _price
        ) external payable onlyUsers {
            IERC20 token = _addressToken[_token];
            require(msg.value >= _minDeposit(), "Not enough value");
            require(_password != bytes32(0), "Incorrect password"); 
            require(address(token) != address(0), "Incorrect token");
                    
            SafeERC20.safeTransferFrom(token, msg.sender, address(this), _amount);

            unchecked {
                ++totalOrders;
            }

            _orders[totalOrders].seller = payable(msg.sender);
            _orders[totalOrders].token = _token;
            _orders[totalOrders].price = _price;
            _orders[totalOrders].amount = _amount;
            _orders[totalOrders].deposit = msg.value;
            _orders[totalOrders].password = _password;        

            emit orderPlaced(
                totalOrders,
                msg.sender
            );
        }

    event orderStatus(uint256 id, string indexed status);

    /// @dev Function for order approval.
        /// * to approve the order, an unencrypted password created by the author is required.
    function approve(uint256 _id, string calldata _key) external payable onlyUsers {
        Order storage newOrder = _orders[_id];

        if (_checkOrder(newOrder) == true) {
            revert UnavailableOrder();
        }

        if (_checkPassword(newOrder.password, _key) == false) {
            revert IncorrectPass();
        }

        require(newOrder.deposit == msg.value, "Incorrect deposit");

        if (newOrder.seller == address(0) && newOrder.buyer != address(0)) {            
            IERC20 token = _addressToken[newOrder.token];
            require(newOrder.buyer != msg.sender, "It is your order!");
            SafeERC20.safeTransferFrom(token, msg.sender, address(this), newOrder.amount);
            newOrder.seller = payable(msg.sender);
            emit orderStatus(_id, "Approved");
        }   
        else if (newOrder.buyer == address(0) && newOrder.seller != address(0)) {
            require(newOrder.seller != msg.sender, "It is your order!");
            newOrder.buyer = payable(msg.sender);
            emit orderStatus(_id, "Approved");
        } else {
            revert ("Order has been approved!");
        }       
    }

    /// @dev Function to complete the order.
        /// * only the seller can complete the order.
        /// * transaction fee 0.5 percent of the deposit amount.
        /// * one part of the commission is transferred to the owner contract,
        /// * second part is transferred to the "FennecCoin" contract for redistribution among stakeholders.        
    function exchange(uint256 _id) external {
        Order storage newOrder = _orders[_id];

        if (_checkOrder(newOrder) == true) {
            revert UnavailableOrder();
        }

        require(payable(msg.sender) == newOrder.seller, "You are not a seller!");

        IERC20 token = _addressToken[newOrder.token];
        
        delete newOrder.password;
        newOrder.seller.transfer(newOrder.deposit * 199 / 200);
        newOrder.buyer.transfer(newOrder.deposit * 199 / 200);
        SafeERC20.safeTransfer(token, newOrder.buyer, newOrder.amount);
        owner.transfer(newOrder.deposit / 200);
        fennecCoin.transfer(newOrder.deposit / 200);

        unchecked {
            ++_userInfo[msg.sender].completedOrders;
            ++_userInfo[newOrder.buyer].completedOrders;
        }

        emit orderStatus(_id, "Exchanged");
    }

    /// @dev Function to cancel the order.
        /// * only the author can cancel the order.
        /// * transaction fee 0.5 percent of the deposit amount.
    function cancel(uint256 _id) external {
        Order storage newOrder = _orders[_id];
        
        if (_checkOrder(newOrder) == true) {
            revert UnavailableOrder();
        }
        
        require(newOrder.seller == msg.sender || newOrder.buyer == msg.sender, "It's not your order!");

        if (newOrder.seller == address(0)) {
            delete newOrder.password;
            newOrder.buyer.transfer(newOrder.deposit * 199 / 200);
            owner.transfer(newOrder.deposit / 200);
            emit orderStatus(_id, "Canceled");
        }    
        else if (newOrder.buyer == address(0)) {
            IERC20 token = _addressToken[newOrder.token];
            delete newOrder.password;
            SafeERC20.safeTransfer(token, newOrder.seller, newOrder.amount);
            newOrder.seller.transfer(newOrder.deposit * 199 / 200);
            owner.transfer(newOrder.deposit / 200);
            emit orderStatus(_id, "Canceled");
        }
        else {
            revert ("Order has been approved!");
        }
    }

    /// Service functions
    
    /// @dev Сhecking orders and passwords
    function _checkOrder(Order memory _newOrder) private pure returns(bool) {
        return 
            _newOrder.buyer == address(0) && 
            _newOrder.seller == address(0) &&
            _newOrder.password == bytes32(0);
    }

}