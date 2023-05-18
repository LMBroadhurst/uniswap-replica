// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;


import "../../src/V1/Exchange.sol";
import "../mocks/ERC20Mintable.sol";
import "forge-std/Test.sol";
import "forge-std/Vm.sol";


contract V1Test is Test {

//    Vm vm = Vm(HEVM_ADDRESS);
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
        uint256 homerLiquidity = userCreatesLiquidExchange(homer, homersEth, homersTokens);

        // final sanity check on exchange
        assert(address(exchange).balance == homersEth);

        // marge adds liquidity to existing exchange
        uint256 margesEth = 3e1;
        uint256 margesTokens = 9e1;
        uint256 margeLiquidity = userAddsLiquidityToExchange(marge, margesEth, margesTokens);

        // Exchange balances
        assert(address(exchange).balance == (homersEth + margesEth));
        assertApproxEqAbs(IERC20(token1).balanceOf(address(exchange)), margesTokens + homersTokens, 10);

        // Luni Balances & totalSupply
        assert(IERC20(exchange).balanceOf(marge) == margeLiquidity);
        assert(IERC20(exchange).balanceOf(homer) == homerLiquidity);
        assert(IERC20(exchange).totalSupply() == (homerLiquidity + margeLiquidity));
    }

    function testRemovesLiquidityFromExchange() public {
        uint256 margeEth = 1e2;
        uint256 margeTokens = 5e2;
        uint256 homerEth = 2e2;
        uint256 homerTokens = 1e3;

        // Homer and Marge add liquidity to the pool
        userCreatesLiquidExchange(marge, margeEth, margeTokens);
        userAddsLiquidityToExchange(homer, homerEth, homerTokens);
        assert(IERC20(exchange).balanceOf(marge) == 1e2);
        assert(IERC20(exchange).balanceOf(homer) == 2e2);

        // Marge removes 5e1 of liquidity
        vm.prank(marge);
        (uint256 ethRedeemAmount, uint256 tokenRedeemAmount)
            = exchange.removeLiquidity(5e1, 4e1, 2e2, block.timestamp + 12 seconds);

        // assertions for marge
        assert(IERC20(exchange).balanceOf(marge) == 1e2 - 5e1);
        assert(IERC20(token1).balanceOf(marge) == (1e3 - 5e2) + tokenRedeemAmount);

        console.log(((margeTokens + homerTokens) - tokenRedeemAmount));
        console.log(IERC20(token1).balanceOf(address(exchange)));

        // assertions for exchange, approx to account for gas/1 wei check
        assertApproxEqAbs(IERC20(token1).balanceOf(address(exchange)), ((margeTokens + homerTokens) - tokenRedeemAmount), 10);
        assertApproxEqAbs(address(exchange).balance, ((margeEth + homerEth)- ethRedeemAmount), 10);
    }

    function testRemovesTooMuchLiquidityFromExchange() public {
        uint256 margeEth = 1e2;
        uint256 margeTokens = 5e2;

        // Marge add liquidity to the pool
        userCreatesLiquidExchange(marge, margeEth, margeTokens);

        // Marge attempts to remove 1e7 liquidity
        vm.startPrank(marge);
        vm.expectRevert();
        exchange.removeLiquidity(3e2, 9.9e2, 4.9e2, block.timestamp + 12 seconds);
        vm.stopPrank();
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

}