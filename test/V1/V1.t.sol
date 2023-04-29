// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../src/V1/Exchange.sol";
import "../mocks/ERC20Mintable.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";

interface CheatCodes {
    function prank(address) external;

    function roll(uint256) external;

    function warp(uint256 x) external;

    function expectRevert(bytes calldata msg) external;
}

contract V1Test is DSTest {

    CheatCodes cheats = CheatCodes(HEVM_ADDRESS);

    Exchange exchange;
    ERC20Mintable token1;

    address lewis = address(0x1);
    address michael = address(0x2);

    function setUp() public {
        token1 = new ERC20Mintable("SwapToken", "SWAP");
        exchange = new Exchange(address(token1)); 

        // Lewis mints token1 tokens to add to the exchange
        token1.mint(100_000_000_000_000_000_000_000, lewis); 
        uint256 lewisBalanceToken1 = IERC20(token1).balanceOf(lewis);
        assert(lewisBalanceToken1 == 100_000_000_000_000_000_000_000);      
    }

    function testAddLiquidityToNewExchange() public {
        // Ensure exchange has no balance
        assert(exchange.getTokenReserves() == 0);

        //        token1.approve(address(exchange), 1_000_000);
//        token1.transferFrom(lewis, address(exchange), 1_000_000);
//        assert(exchange.getTokenReserves() == 1_000_000);
    }

}