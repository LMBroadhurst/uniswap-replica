// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../src/V1/Exchange.sol";
import "../mocks/ERC20Mintable.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";


contract V1Test is Test {

    Exchange exchange;
    ERC20Mintable token1;

    address lewis = address(0x1);
    address michael = address(0x2);

    function setUp() public {
        token1 = new ERC20Mintable("SwapToken", "SWAP");
        exchange = new Exchange(address(token1));        
    }

    function testAddLiquidityToNewExchange() public {
        // Ensure exchange has no balance
        assert(exchange.getTokenReserves() == 0);

        // Lewis mints token1 tokens to add to the exchange
        token1.mint(100_000_000, lewis);
        uint256 lewisBalanceToken1 = IERC20(token1).balanceOf(lewis);
        assert(lewisBalanceToken1 == 100_000_000);

        bool success = IERC20(token1).transferFrom(address(exchange), lewis, 50_000_000);
        require(success, "Transfer failed");

        assert(exchange.getTokenReserves() == 50_000_000);
        assert(token1.balanceOf(lewis) == 50_000_000);
    }

}