// SPDX-License-Identifier: MIT
// FennecTechnology Contracts (version v0.1) (token/FennecCoin.sol)

pragma solidity ^0.8.17;

import "./ICO/FennecICO.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

uint256 constant TOTALSUPPLY = 1000000;

/// @title FennecCoin
    /// @author 'FennecTechnology'
    /// @notice Native token of FennecTechnology.
    /// @dev ERC20 standart contract import from OpenZeppelin.
    /// @dev Stakeholders receive profit from all projects.

contract FennecCoin is ERC20 {

    /// @return 'Variables in storage'
        /// @dev stake is amount of tokens burned;
        /// @dev totalStake is the total amount of tokens burned;
        /// @dev payout period is 2 days.
    
    mapping(address => uint256) public stake;
    uint256 public totalStake;
    uint256 public payoutDate;
    FennecICO public fennecICO;

    /// @dev 'constructor'
        /// setting all required variables;
        /// minting the required amount of tokens.        

    constructor(address _priceFeed) ERC20("FennecCoin", "Fennec") {
        fennecICO = new FennecICO(_priceFeed, msg.sender);
        _mint(address(fennecICO), TOTALSUPPLY * 10 ** decimals());
    }

    /// @dev Increase stake:
        /// input data is amount of FennecCoin (with decimal);
        /// for staking need to burn FennecCoin;
        /// period for staking FennecCoin is 30 days.
        /// freeze period is 60 days
    
    function increaseStake(uint256 amount) external {
        require(amount > 0, "Incorrect amount");
        require(balanceOf(msg.sender) >= amount, "Not enough tokens on balance");        

        if (payoutDate > 0 && payoutDate - 60 days > block.timestamp) {
            _burn(msg.sender, amount);
            unchecked {
                stake[msg.sender] += amount;
                totalStake += amount;
            }
        }
        else if (payoutDate + 2 days < block.timestamp) {
            _burn(msg.sender, amount);
            unchecked {
                payoutDate = block.timestamp + 90 days;
                stake[msg.sender] += amount;
                totalStake += amount;
            }
        }
        else {
            revert("You can't stake today");
        }
    }

    /// @dev Paying dividends for stakeholders:
        /// dividends are paid within 2 days;
        /// amount of dividends is a percentage of the total amount of frozen FennecCoin;
        /// after the payment of dividends, stake is reset to zero and the FennecCoin are returned.
        
    function payoutDividend() external {
        require(address(this).balance > 0, "No profit received");
        uint256 _stake = stake[msg.sender];
        require(_stake > 0, "Increase stake!");
        require(payoutDate < block.timestamp && payoutDate + 2 days > block.timestamp, "Dividend payments will be later");        
                
        unchecked {
            stake[msg.sender] = 0;
            payable(msg.sender).transfer(address(this).balance * _stake / totalStake);
            totalStake -= _stake;
            _mint(msg.sender, _stake); 
        }       
    }

    /// @dev Function for receive profit from all Fennec projects
        
    receive () external payable {        
    }
}