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

    address homer = address(0x12345);
    address marge = address(0x23456);

    function setUp() public {
        // Create the ERC20 token and the Exchange
        token1 = new ERC20Mintable("Loptimism", "LOP");
        exchange = new Exchange(address(token1)); 

        // V1Test mints token1 tokens
        token1.mint(1e18, address(this));
        uint256 contractBalanceToken1 = IERC20(token1).balanceOf(address(this));
        assert(contractBalanceToken1 == 1e18);

        // Send Homer & Marge 1e3 of LOP & add ether
        vm.deal(homer, 1e3 ether);
        token1.approve(homer, 1e3);
        token1.transfer(homer, 1e3);
        assert(homer.balance == 1e3 ether);
        assert(IERC20(token1).balanceOf(homer) == 1e3);

        vm.deal(marge, 1e3 ether);
        token1.approve(marge, 1e3);
        token1.transfer(marge, 1e3);
        assert(marge.balance == 1e3 ether);
        assert(IERC20(token1).balanceOf(marge) == 1e3);
    }


    function testAddLiquidityToNewExchange() public {
        // Ensure exchange has no balance
        assert(exchange.getTokenReserves() == 0);

        // addLiquidity via homer' address
        uint256 homersEth = 1e1;
        uint256 homersTokens = 5e1;
        uint256 liquidityMinted = userAddsLiquidityToExchange(homer, homersEth, homersTokens);

        // Ensure address of exchange has received the tokens
        assert(IERC20(token1).balanceOf(address(exchange)) == homersTokens);
        assert(address(exchange).balance == homersEth);

        // Ensure homer has sent his eth and tokens, and received his LUNI tokens
        assert(IERC20(token1).balanceOf(homer) == (1e3 - homersTokens));
        assert(address(homer).balance == 1e3 ether - homersEth);
        assert(IERC20(exchange).balanceOf(homer) == liquidityMinted);
    }


    function testAddLiquidityToExistingExchange() public {
        uint256 homersEth = 2e1;
        uint256 homersTokens = 6e1;
        userCreatesLiquidExchange(homer, homersEth, homersTokens);

        // final sanity check on exchange
        assert(address(exchange).balance == homersEth);

        // marge adds liquidity to existing exchange
        vm.startPrank(marge);
        uint256 _ethAmount = 3e1;
        uint256 _tokenAmount = 9e1;
        token1.approve(address(exchange), _tokenAmount);
        uint256 liquidityMinted = exchange.addLiquidity
            {value: _ethAmount}
            (_ethAmount, _tokenAmount, block.timestamp + 12 seconds);
        vm.stopPrank();

        assert(address(exchange).balance == (homersEth + _ethAmount));
    }


    function userAddsLiquidityToExchange(address _user, uint256 _ethAmount, uint256 _tokenAmount)
    public returns (uint256) {
        vm.startPrank(homer);
        token1.approve(address(exchange), _tokenAmount);
        uint256 liquidityMinted = exchange.addLiquidity
            {value: _ethAmount}
            (_ethAmount, _tokenAmount, block.timestamp + 12 seconds);
        vm.stopPrank();

        return liquidityMinted;
    }

    function userCreatesLiquidExchange(address _user, uint256 _usersEth, uint256 _usersTokens) public {
        // Check of exchange reserves
        assert(exchange.getTokenReserves() == 0);

        // Add liquidity via homer
        uint256 mintedLiquidity = userAddsLiquidityToExchange(homer, _usersEth, _usersTokens);

        // sanity check we have an exchange with liq. and homer received tokens
        assert(IERC20(token1).balanceOf(address(exchange)) == _usersTokens);
        assert(address(exchange).balance == _usersEth);
        assert(IERC20(exchange).balanceOf(address(_user)) == mintedLiquidity);
    }

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