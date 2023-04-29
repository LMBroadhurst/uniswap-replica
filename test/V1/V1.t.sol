// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../src/V1/Exchange.sol";
import "../mocks/ERC20Mintable.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";


contract V1Test is Test {

    Exchange exchange;
    ERC20Mintable token1;

    function setUp() public {
        token1 = new ERC20Mintable("SwapToken", "SWAP");
        exchange = new Exchange(address(token1));        
    }

    function testAddLiquidity() public view {
        assert(exchange.getReserve() == 0);

    }

}