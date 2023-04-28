// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";

contract Exchange is ERC20 {
    // public variable, meaning anyone can find out the token that this exchange is linked to
    address public tokenAddress;
    address public factoryAddress;

    constructor(address _tokenAddress)
    ERC20("LuniSwap V1", "LUNI-V1") {
        require(_tokenAddress != address(0), "Token address cannot be 0");
        
        tokenAddress = _tokenAddress;
        factoryAddress = msg.sender;
    }

    // Need to able to add liquidity to the exchange LP
    // Why public?
    // Why payable? Allows function to receive ETH and add ETH to the Exchange contract
    function addLiquidity(uint256 _tokenAmount) public payable {
        IERC20 token = IERC20(tokenAddress);
        token.transferFrom(msg.sender, address(this), _tokenAmount);
    }

    function getPrice(uint256 inputReserve, uint256 outputreserve)
    public pure returns (uint256)
    {
        require(inputReserve > 0 && outputreserve > 0, "Reserves must be greater than 0");
        return inputReserve / outputreserve;
    }

    // Helper Functions
    function getReserve() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }
}