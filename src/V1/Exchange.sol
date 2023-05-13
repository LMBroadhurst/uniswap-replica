// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "openzeppelin/contracts/token/ERC20/IERC20.sol";
import "openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IFactory {
  function getExchange(address _tokenAddress) external returns (address);
}

interface IExchange {
    function ethToTokenSwap(uint256 _minTokens) external payable;

    function ethToTokenTransfer(uint256 _minTokens, address _recipient) external payable;
}

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

    // -- LIQUDITY IN/OUT -- //

    // Need to able to add liquidity to the exchange LP
    // Why public?
    // Why payable? Allows function to receive ETH and add ETH to the Exchange contract
    function addLiquidity(uint256 _tokenAmount) public payable returns (uint256 liquidity) {
        if (getTokenReserves() == 0) {
            IERC20 token = IERC20(tokenAddress);
            token.transferFrom(msg.sender, address(this), _tokenAmount);

            liquidity = address(this).balance;
            _mint(msg.sender, liquidity);

            return liquidity;
        } else {
            // Need to - msg.value from balance as the function has already taken the msg.balance from payable
            uint256 ethReserve = address(this).balance - msg.value;
            uint256 tokenReserve = getTokenReserves();

            uint256 tokenAmount = (msg.value * tokenReserve) / ethReserve;
            require(_tokenAmount >= tokenAmount, "insufficient token amount");
            IERC20(tokenAddress).transferFrom(msg.sender, address(this), tokenAmount);

            liquidity = (msg.value * totalSupply()) / ethReserve;
            _mint(msg.sender, liquidity);

            return liquidity;
        }
    }

    function removeLiquidity(uint256 _amount) public returns (uint256, uint256) {
        require(_amount > 0, "amount must be greater than 0");

        uint256 ethAmount = (address(this).balance * _amount) / totalSupply();
        uint256 tokenAmount = (getTokenReserves() * _amount) / totalSupply();

        _burn(msg.sender, _amount);
        payable(msg.sender).transfer(ethAmount);
        IERC20(tokenAddress).transfer(msg.sender, tokenAmount);

        return (ethAmount, tokenAmount);
    }

    // -- SWAPS -- //

    // Need to - msg.value from balance as the function has already taken the msg.balance from payable
    // @dev -- Swap ETH for Token functionality.
    function ethToToken(uint256 _minTokens, address recipient) internal {
        uint256 tokenReserve = getTokenReserves();
        uint256 tokensBought = getAmount(
            msg.value,
            address(this).balance - msg.value,
            tokenReserve
        );

        require(tokensBought >= _minTokens, "insufficient output amount");
        IERC20(tokenAddress).transfer(recipient, tokensBought);
    }

    // @dev -- Swap ETH for Token, called function.
    function ethToTokenSwap(uint256 _minTokens) public payable {
        ethToToken(_minTokens, msg.sender);
    }

    // @dev -- Swap ETH for Token, called function. Send to non msg.sender address.
    function ethToTokenTransfer(uint256 _minTokens, address _recipient) public payable {
        ethToToken(_minTokens, _recipient);
    }

    function tokenToEthSwap(uint256 _tokensSold, uint256 _minEth) public payable {
        uint256 tokenReserve = getTokenReserves();
        uint256 ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );
        require(ethBought >= _minEth, "insufficient output amount");

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokensSold);
        payable(msg.sender).transfer(ethBought);
    }

    function tokenToTokenSwap(
        uint256 _tokensSold,
        uint256 _minTokensBought,
        address _tokenAddress
    ) public {
        address exchangeAddress = IFactory(factoryAddress).getExchange(_tokenAddress);
        require(exchangeAddress != address(this) && exchangeAddress != address(0), "invalid exchange address");

        uint256 tokenReserve = getTokenReserves();
        uint256 ethBought = getAmount(
            _tokensSold,
            tokenReserve,
            address(this).balance
        );

        IERC20(tokenAddress).transferFrom(msg.sender, address(this), _tokensSold);
        IExchange(exchangeAddress).ethToTokenSwap{value: ethBought}(_minTokensBought);
    }

    // -- HELPERS -- //

    // Low level functions -- make it private, why?
    // Would also be pointless to be a public function
    function getAmount(
        uint256 inputAmount,
        uint256 inputReserve,
        uint256 outputReserve
    ) private pure returns (uint256) {
        require(inputReserve > 0 && outputReserve > 0, "Reserves must be greater than 0");

        uint256 inputAmountWithFee = inputAmount * 99;
        uint256 numerator = inputAmountWithFee * outputReserve;
        uint256 denominator = (inputReserve * 100) + inputAmountWithFee;

        return numerator / denominator;
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

        uint256 tokenReserve = getTokenReserves();

        return getAmount(_tokenSold, tokenReserve, address(this).balance);
    }
}