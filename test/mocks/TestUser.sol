// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../src/V2/LuniswapV2Pair.sol";

contract TestUser {

    constructor() {}

    function provideLiquidity(
        address pairAddress_,
        address token0Address_,
        address token1Address_,
        uint256 amount0_,
        uint256 amount1_
    ) public {
        ERC20(token0Address_).transfer(pairAddress_, amount0_);
        ERC20(token1Address_).transfer(pairAddress_, amount1_);

        LuniswapV2Pair(pairAddress_).mint();
    }

    function withdrawLiquidity(address pairAddress_) public {
        LuniswapV2Pair(pairAddress_).burn();
    }
}