// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "forge-std/Test.sol";
import "../mocks/ERC20Mintable.sol";

contract V1Test is Test {

    function setUp() public {
        token0 = new ERC20Mintable("ETH", "ETH");
        token1 = new ERC20Mintable("SwapToken", "SWAP");
        pair = new ZuniswapV2Pair(address(token0), address(token1));

        token0.mint(10 ether);
        token1.mint(10 ether);
    }

    function testAddLiquidity() public {
        assert(true);
    }

}