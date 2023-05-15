// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;


import "../../src/V1/Exchange.sol";
import "../mocks/ERC20Mintable.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";


contract V1Test is DSTest {

    Vm vm = Vm(HEVM_ADDRESS);
    Exchange exchange;
    ERC20Mintable token1;

    address lewis = address(0x12345);
    address michael = address(0x23456);

    function setUp() public {
        // Create the ERC20 token and the Exchange
        token1 = new ERC20Mintable("Loptimism", "LOP");
        exchange = new Exchange(address(token1)); 

        // V1Test mints token1 tokens
        token1.mint(1e18, address(this));
        uint256 contractBalanceToken1 = IERC20(token1).balanceOf(address(this));
        assert(contractBalanceToken1 == 1e18);

        // Send Lewis & Michael 1e3 of LOP & add ether
        vm.deal(lewis, 1e3 ether);
        token1.approve(lewis, 1e3);
        token1.transfer(lewis, 1e3);
        assert(lewis.balance == 1e3 ether);
        assert(IERC20(token1).balanceOf(lewis) == 1e3);

        vm.deal(michael, 1e3 ether);
        token1.approve(michael, 1e3);
        token1.transfer(michael, 1e3);
        assert(michael.balance == 1e3 ether);
        assert(IERC20(token1).balanceOf(michael) == 1e3);
    }

    function testAddLiquidityToNewExchange() public {
        // Ensure exchange has no balance
        assert(exchange.getTokenReserves() == 0);

        // addLiquidity via lewis' address
        uint256 liquidity = lewisAddsLiquidityToExchange(1e1);

        // Ensure address of exchange has received the tokens & lewis sent the tokens
        assert(IERC20(token1).balanceOf(address(exchange)) == 1e1);
        assert(address(exchange).balance == 1e1);
        assert(IERC20(token1).balanceOf(lewis) == 0);
        assert(lewis.balance == (1e3 ether - 1e1));

        // Ensure lewis has received the LUNI-V1 tokens
        assert(IERC20(exchange).balanceOf(lewis) == liquidity);
    }
//
//    function testAddLiquidityToExistingExchange() public {
//        // Check of exchange reserves
//        assert(exchange.getTokenReserves() == 0);
//
//        // Add liquidity and check reserves
//        lewisAddsLiquidityToExchange(1e9);
//        assert(IERC20(token1).balanceOf(address(exchange)) == 1e9);
//        assert(address(exchange).balance == 1e9);
//
//        uint256 liquidity = michaelAddsLiquidityToExchange(1e9);
//        assert(IERC20(exchange).balanceOf(michael) == liquidity);
//    }
//
//    function testRemovesLiquidityFromExchange() public {
//        // Lewis and Michael add liquidity to the pool
//        lewisAddsLiquidityToExchange(1e6);
//        michaelAddsLiquidityToExchange(2e7);
//        assert(IERC20(exchange).balanceOf(lewis) == 1e6);
//        assert(IERC20(exchange).balanceOf(michael) == 2e7);
//
//        // Lewis removes 2e4 of liquidity
//        vm.prank(lewis);
//        exchange.removeLiquidity(2e4);
//
//        // Michael removes 9e2 of liquidity
//        vm.prank(michael);
//        exchange.removeLiquidity(9e2);
//
//        // assertions
//        assert(IERC20(exchange).balanceOf(lewis) == (1e6 - 2e4));
//        assert(IERC20(exchange).balanceOf(michael) == (2e7 - 9e2));
//        assert(address(exchange).balance == (1e6 - 2e4) + (2e7 - 9e2));
//        assert(IERC20(token1).balanceOf(address(exchange)) == (1e6 - 2e4) + (2e7 - 9e2));
//    }
//
//    function testRemovesTooMuchLiquidityFromExchange() public {
//        // Lewis and Michael add liquidity to the pool
//        lewisAddsLiquidityToExchange(1e6);
//        michaelAddsLiquidityToExchange(2e7);
//        assert(IERC20(exchange).balanceOf(lewis) == 1e6);
//        assert(IERC20(exchange).balanceOf(michael) == 2e7);
//
//        // lewis attempts to remove 1e7 liquidity
//        vm.startPrank(lewis);
//        vm.expectRevert();
//        exchange.removeLiquidity(1e7);
//        vm.stopPrank();
//    }
//
//    function lewisAddsLiquidityToExchange(uint256 _amount) public returns (uint256) {
//        vm.startPrank(lewis);
//        token1.approve(address(exchange), _amount);
//        uint256 liquidity = exchange.addLiquidity{value: _amount}(_amount);
////        console.log("Liquidity of Lewis (%s) is %s coins ", lewis, liquidity);
//        vm.stopPrank();
//
//        return liquidity;
//    }
//
//    function michaelAddsLiquidityToExchange(uint256 _amount) public returns (uint256) {
//        vm.startPrank(michael);
//        token1.approve(address(exchange), _amount);
//        uint256 liquidity = exchange.addLiquidity{value: _amount}(_amount);
////        console.log("Liquidity of Michael (%s) is %s coins ", michael, liquidity);
//        vm.stopPrank();
//
//        return liquidity;
//    }

}