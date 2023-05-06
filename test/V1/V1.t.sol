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

        // Send Lewis 1e9 of LOP & add ether
        vm.deal(lewis, 1e9 ether);
        token1.approve(lewis, 1e9);
        token1.transfer(lewis, 1e9);
        assert(lewis.balance == 1e9 ether);
        assert(IERC20(token1).balanceOf(lewis) == 1e9);
    }

    function testAddLiquidityToNewExchange() public {
        // Ensure exchange has no balance
        assert(exchange.getTokenReserves() == 0);

        // addLiquidity via lewis' address
        vm.startPrank(lewis);
        token1.approve(address(exchange), 1e9);
        uint256 liquidity = exchange.addLiquidity{value: 1e9}(1e9);
        console.log("Liquidity: ", liquidity);
        vm.stopPrank();

        // Ensure address of exchange has received the tokens & lewis sent the tokens
        assert(IERC20(token1).balanceOf(address(exchange)) == 1e9);
        assert(address(exchange).balance == 1e9);
        assert(IERC20(token1).balanceOf(lewis) == 0);
        assert(lewis.balance == (1e9 ether - 1e9));
    }

    function testAddLiquidityToExistingExchange() public view {
        // Ensure exchange has a +ve balance
//        assert(exchange.getTokenReserves() > 0);
    }

}