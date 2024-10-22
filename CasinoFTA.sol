// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract CasinoFTA is Ownable {
    IERC20 public token;
    uint256 public constant HOUSE_EDGE = 10; // 10% house edge
    uint256 public randomNumber = 0;

    event BetPlaced(address indexed player, uint256 betAmount, uint256 playerInput, uint256 randomNumber, bool win, uint256 payout);
    event Withdrawal(address indexed owner, uint256 amount);

    // Constructor: specify the token address during contract deployment
    constructor(address tokenAddress) Ownable(msg.sender) {
        require(tokenAddress != address(0), "Token address cannot be zero address");
        token = IERC20(tokenAddress);
    }

    function placeBet(uint256 betAmount, uint256 playerInput) external {
        require(betAmount > 0, "Bet amount must be greater than zero");
        require(playerInput >= 1 && playerInput <= 100, "Input must be between 1 and 100");

        // Transfer betAmount from player to contract
        require(token.transferFrom(msg.sender, address(this), betAmount), "Transfer failed");

        // Generate a random number between 1 and 100
        randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty))) % 100 + 1;

        // Determine if the player wins (if player input is greater than random number)
        bool win = playerInput > randomNumber;

        uint256 payout = 0;

        if (win) {
            // Calculate payout (bet amount minus house edge)
            payout = betAmount * (100 - HOUSE_EDGE) / 100 * 2;
            require(token.balanceOf(address(this)) >= payout, "Not enough tokens in contract");
            require(token.transfer(msg.sender, payout), "Payout transfer failed");
        }

        // Emit the event with the player's bet and the random number result
        emit BetPlaced(msg.sender, betAmount, playerInput, randomNumber, win, payout);
    }

    // Owner can withdraw tokens from the contract
    function withdraw(uint256 amount) external onlyOwner {
        require(token.balanceOf(address(this)) >= amount, "Not enough tokens in contract");
        require(token.transfer(owner(), amount), "Withdrawal failed");

        emit Withdrawal(owner(), amount);
    }

    // Allow the owner to deposit tokens into the contract
    function deposit(uint256 amount) external onlyOwner {
        require(amount > 0, "Deposit amount must be greater than zero");
        require(token.transferFrom(msg.sender, address(this), amount), "Deposit failed");
    }

    // Fallback function to prevent accidental ether transfers
    receive() external payable {
        revert("Contract does not accept Ether");
    }
}
