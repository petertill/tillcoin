// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MyToken is ERC20, Ownable {
    uint256 reserveEther; //Native token reserve
    uint256 public constant INITIAL_RESERVE_ETHER = 0 ether; // Initial reserve for testing
    uint256 public constant MAX_SUPPLY = 900000000 * 10 ** 18; // 900 million tokens

    event TokensBought(address indexed buyer, uint256 amount, uint256 totalPrice, uint256 currentPrice);
    event TokensSold(address indexed seller, uint256 amount, uint256 totalEarned, uint256 currentPrice);

    //_mint(msg.sender, 900000000 * 10 ** decimals());

    constructor() ERC20("TillCoin", "TCO") Ownable(msg.sender) {
        reserveEther = INITIAL_RESERVE_ETHER;
    }

    function getLiquidityPool() external view returns (uint256) {
        return reserveEther;
    }

    function calculateTokenPrice() public view returns (uint256) {
        if (totalSupply() == 0) {
            return 0.5 ether; // Initial price when there are no tokens minted
        }
        return (reserveEther * 10**18) / totalSupply();
    }

    function buyTokens(uint256 numberOfTokens) external payable {
        uint256 totalPrice = calculateTokenPrice() * numberOfTokens;
        require(msg.value == totalPrice, "Incorrect payment amount");

        require(totalSupply() + numberOfTokens * 10**18 <= MAX_SUPPLY, "Exceeds maximum supply");

        reserveEther += msg.value; // Add purchased Ether to the reserve
        _mint(msg.sender, numberOfTokens * 10**18); // Mint the requested number of tokens

        emit TokensBought(msg.sender, numberOfTokens, totalPrice, calculateTokenPrice());
    }

    function sellTokens(uint256 numberOfTokens) external payable  {
        require(balanceOf(msg.sender) >= numberOfTokens * 10**18, "Insufficient balance");

        uint256 totalEarned = (reserveEther * 10**18 * numberOfTokens) / totalSupply();
        reserveEther -= totalEarned; // Subtract Ether from the reserve
        _burn(msg.sender, numberOfTokens * 10**18); // Burn the sold tokens

        bool success = payable(msg.sender).send(totalEarned);
        require(success, "Ether transfer failed");

        /*(bool sent, bytes memory data) = payable(msg.sender).call{value: totalEarned}(""); //Matic was not sent but tx and burnng was successfull
        require(sent, "Failed to send Ether");*/

        /*(bool success, ) = payable(msg.sender).call{value: totalEarned}("");
        (bool sent, bytes memory data) = _to.call{value: msg.value}("");
        require(sent, "Failed to send Ether");
        require(success, "Ether transfer failed");*/

        emit TokensSold(msg.sender, numberOfTokens, totalEarned, calculateTokenPrice());
    }

    // Owner stuff

    function airdrop(address to, uint256 amount) public onlyOwner {
        _mint(to, amount * 10 ** decimals());
    }

    function getContractBalance() external view onlyOwner returns (uint256) {
        return address(this).balance;
    }
}
