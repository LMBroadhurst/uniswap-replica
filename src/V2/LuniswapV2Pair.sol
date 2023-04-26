// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "openzeppelin-contracts\contracts\token\ERC20\ERC20.sol";
import "openzeppelin-contracts\contracts\utils\math\Math.sol";

error InsufficientLiquidityMinted();
error InsufficientLiquidityBurned();
error TransferFailed();

contract LuniswapV2Pair is ERC20, Math {

    // TODO: More info
    uint256 constant MINIMUM_LIQUIDITY = 1000;

    // addresses for the relevant tokens in the token Pair
    address public token0;
    address public token1;

    // Use the reserve variables to track the pools reserves
    uint256 private reserve0;
    uint256 private reserve1;

    // Events marking significant log worthy actions
    event Burn(address indexed sender, uint256 amount0, uint256 amount1);
    event Mint(address indexed sender, uint256 amount0, uint256 amount1);
    event Sync(uint256 reserve0, uint256 reserve1);

    constructor(address token0_, address token1_) ERC20("LuniswapV2 Pair", "LUNIV2", 18) {
        token0 = token0_;
        token1 = token1_;
    }

    // @dev this is the contract that is called when you add liqudity to a pair
    // When you add liquidity - new LP tokens are minted
    // When you remove liquidity - LP tokens are burned
    // Math: https://jeiwan.net/posts/programming-defi-uniswapv2-1/
    function mint() public {

        // where does getReserves come from?
        (uint112 _reserve0, uint112 _reserve1, ) = getReserves();

        // balances of each coin used in the V2Pair
        uint256 balance0 = IERC20(token0).balanceOf(address(this));
        uint256 balance1 = IERC20(token1).balanceOf(address(this));

        // wouldn't this be -ve?
        uint256 amount0 = balance0 - reserve0;
        uint256 amount1 = balance1 - reserve1;

        // ?
        uint256 liquidity;

        if (totalSupply == 0) {
            liquidity = Math.sqrt(amount0 * amount1) - MINIMUM_LIQUIDITY;
            _mint(address(0), MINIMUM_LIQUIDITY);
        } else {
            liquidity = Math.min(
                (amount0 * totalSupply) / reserve0,
                (amount1 * totalSupply) / reserve1
            );
        }

        if (liquidity <= 0) revert InsufficientLiquidityMinted();

        _mint(msg.sender, liquidity);

        _update(balance0, balance1);

        emit Mint(msg.sender, amount0, amount1);
    }
}
