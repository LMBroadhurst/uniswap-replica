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
        uint256 initialContractTokenBalance = IERC20(token1).balanceOf(address(this));

        uint256 homersEth = 2e1;
        uint256 homersTokens = 6e1;
        uint256 homerLiquidity = userCreatesLiquidExchange(homer, homersEth, homersTokens);

        // final sanity check on exchange
        assert(address(exchange).balance == homersEth);

        // marge adds liquidity to existing exchange
        uint256 margesEth = 3e1;
        uint256 margesTokens = 9e1;
        uint256 margeLiquidity = userAddsLiquidityToExchange(marge, margesEth, margesTokens);

        // Exchange balances
        assert(address(exchange).balance == (homersEth + margesEth));

        // @audit -- Check this totalExchangeBalance out, think the 1 wei addition is causing a problem
//        uint256 totalExchangeTokens = margesTokens + homersTokens;
//        console.log(IERC20(token1).balanceOf(address(exchange)), totalExchangeTokens);

        // Luni Balances & totalSupply
        assert(IERC20(exchange).balanceOf(marge) == margeLiquidity);
        assert(IERC20(exchange).balanceOf(homer) == homerLiquidity);
        assert(IERC20(exchange).totalSupply() == (homerLiquidity + margeLiquidity));
    }

    function testRemovesLiquidityFromExchange() public {
        // Homer and Marge add liquidity to the pool
        userCreatesLiquidExchange(marge, margeEth, margeTokens);
        userAddsLiquidityToExchange(homer, homerEth, homerTokens);
        assert(IERC20(exchange).balanceOf(lewis) == 1e6);
        assert(IERC20(exchange).balanceOf(michael) == 2e7);

        // Lewis removes 2e4 of liquidity
        vm.prank(lewis);
        exchange.removeLiquidity(2e4);

        // Michael removes 9e2 of liquidity
        vm.prank(michael);
        exchange.removeLiquidity(9e2);

        // assertions
        assert(IERC20(exchange).balanceOf(lewis) == (1e6 - 2e4));
        assert(IERC20(exchange).balanceOf(michael) == (2e7 - 9e2));
        assert(address(exchange).balance == (1e6 - 2e4) + (2e7 - 9e2));
        assert(IERC20(token1).balanceOf(address(exchange)) == (1e6 - 2e4) + (2e7 - 9e2));
    }


    function userAddsLiquidityToExchange(address _user, uint256 _ethAmount, uint256 _tokenAmount)
    public returns (uint256) {
        vm.startPrank(_user);
        token1.approve(address(exchange), _tokenAmount);
        uint256 liquidityMinted = exchange.addLiquidity
            {value: _ethAmount}
            (_ethAmount, _tokenAmount, block.timestamp + 12 seconds);
        vm.stopPrank();

        return liquidityMinted;
    }

    function userCreatesLiquidExchange(address _user, uint256 _usersEth, uint256 _usersTokens)
    public returns (uint256) {
        // Check of exchange reserves
        assert(exchange.getTokenReserves() == 0);

        // Add liquidity via _user
        uint256 mintedLiquidity = userAddsLiquidityToExchange(_user, _usersEth, _usersTokens);

        // sanity check we have an exchange with liq. and homer received tokens
        assert(IERC20(token1).balanceOf(address(exchange)) == _usersTokens);
        assert(address(exchange).balance == _usersEth);
        assert(IERC20(exchange).balanceOf(address(_user)) == mintedLiquidity);

        return mintedLiquidity;
    }


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

}