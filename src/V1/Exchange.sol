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

    // Need to - msg.value from balance as the function has already taken the msg.balance from payable
    function ethToTokenSwap(uint256 _minTokens) public payable {
        uint256 tokenReserve = getTokenReserves();
        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );
        require(tokensBought >= 0, "insufficient token output");

        IERC20(tokenAddress).transfer(msg.sender, tokensBought);
    }

    function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) public payable {
        uint256 tokenReserve = getTokenReserves();
        uint256 ethBought = getAmount(
            _tokensSold,
            ethReserve,
            address(this).balance
        );
        require(ethBought >= _minEth, "insufficient output amount");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokensSold);
        payable(msg.sender).transfer(ethBought);
    }

    // Helper Functions

    // Low level functions -- make it private, why?
    // Would also be pointless to be a public function
    function getAmount(
        uint256 inputAmount,
        unit256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Reserves must be greater than 0");

        return (inputAmount * outputReserve) / (inputReserve + inputAmount);
    }

    function getTokenReserves() public view returns (uint256) {
        return IERC20(tokenAddress).balanceOf(address(this));
    }

    function getPrice(uint256 inputReserve, uint256 outputreserve)
    public pure returns (uint256)
    {
        require(inputReserve > 0 && outputreserve > 0, "Reserves must be greater than 0");

        return (inputReserve * 1000) / outputreserve;
    }

    // Will need these to display to FE and calculate outputs
    function getTokenAmount(uint256 _ethSold) public view returns (uint256) {
        require(_ethSold > 0, "ETH sold must be over 0");
        uint256 tokenReserve = getTokenReserves();

        return getAmount(_ethSold, address(this).balance, tokenReserve);
    }

    // Will need these to display to FE and calculate outputs
    function getEthAmount(uint256 _tokenSold) public view returns (uint256) {
        require(_tokenSold > 0, "Token sold must be over 0");

        tokenReserve = getTokenReserves();

        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }
}