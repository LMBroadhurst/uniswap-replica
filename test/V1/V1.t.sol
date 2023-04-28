// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../../src/V1/Exchange.sol";
import "../mocks/ERC20Mintable.sol";
import "forge-std/Test.sol";

contract V1Test is Test {

    Exchange exchange;
    address token1;

    function setUp() public {
        token1 = new ERC20Mintable("SwapToken", "SWAP");
        token1.mint(10 ether);

        exchange = new Exchange(token1);        
    }

    function testAddLiquidity() public {
        assert(true);
    }

}