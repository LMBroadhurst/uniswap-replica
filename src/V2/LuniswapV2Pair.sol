// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../libraries/Math.sol";

contract LuniswapV2Pair is Math, ERC20 {

    // -- STATE -- //

    uint256 constant MINIMUM_LIQUIDITY = 1000;

    // token contract addresses
    address public tokenAddress0;
    address public tokenAddress1;

    // Used to track the reserves in pools
    uint128 private tokenReserves0;
    uint128 private tokenReserves1;

    constructor(address _token0, address _token1)
    ERC20("LuniswapV2 Pair", "LUNIV2") 
    {
        tokenAddress0 = _token0;
        tokenAddress1 = _token1;
    }

    // -- ERRORS -- //

    error InsufficientLiquidityMinted();
    error InsufficientLiquidityBurned();
    error TransferFailed();

    // -- EVENTS -- //

    event Burn(address indexed sender, uint256 amount0, uint256 amount1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Sync(uint256 reserve0, uint256 reserve1);

    // -- FUNCTIONS -- //

    function mint() public {
        (uint128 _tokenReserves0, uint128 _tokenReserves1, ) = getReserves();
        uint256 tokenBalance0 = IERC20(tokenAddress0).balanceOf(address(this));
        uint256 tokenBalance1 = IERC20(tokenAddress1).balanceOf(address(this));

        // Should always be positive as we have added liquidity of token0 & token1
        uint256 amount0 = tokenBalance0 - _tokenReserves0;
        uint256 amount1 = tokenBalance1 - _tokenReserves1;

        uint256 liquidity;

        if (totalSupply() == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
            
        } else {
            liquidity = Math.min(
                amount0 * totalSupply() / _tokenReserves0, 
                amount1 * totalSupply() / _tokenReserves1
            );
        }

        if (liquidity == 0) revert InsufficientLiquidityMinted();
    
        _mint(msg.sender, liquidity);
        _update(tokenBalance0, tokenBalance1);
        emit Mint(msg.sender, amount0, amount1);
    }

    function burn() public {
        uint256 balance0 = IERC20(tokenAddress0).balanceOf(address(this));
        uint256 balance1 = IERC20(tokenAddress1).balanceOf(address(this));
        uint256 liquidity = balanceOf(msg.sender);

        uint256 amount0 = (liquidity * balance0) / totalSupply();
        uint256 amount1 = (liquidity * balance1) / totalSupply();

        if (amount0 <= 0 || amount1 <= 0) revert InsufficientLiquidityBurned();

        _burn(msg.sender, liquidity);

        _safeTransfer(tokenAddress0, msg.sender, amount0);
        _safeTransfer(tokenAddress1, msg.sender, amount1);

        balance0 = IERC20(tokenAddress0).balanceOf(address(this));
        balance1 = IERC20(tokenAddress1).balanceOf(address(this));

        _update(balance0, balance1);

        emit Burn(msg.sender, amount0, amount1);
    }


    // -- HELPERS -- //


    function sync() public {
        _update(
            IERC20(tokenAddress0).balanceOf(address(this)),
            IERC20(tokenAddress1).balanceOf(address(this))
        );
    }

    function getReserves() public view returns (uint128, uint128, uint32){
        return (tokenReserves0, tokenReserves1, 0);
    }

    function _update(uint256 balance0, uint256 balance1) private {
        tokenReserves0 = uint128(balance0);
        tokenReserves1 = uint128(balance1);

        emit Sync(tokenReserves0, tokenReserves0);
    }

    function _safeTransfer(address token, address to, uint256 value) private {
        (bool success, bytes memory data) = token.call(abi.encodeWithSignature("transfer(address,uint256)", to, value));
        if (!success || (data.length != 0 && !abi.decode(data, (bool)))) revert TransferFailed();
    }
}
