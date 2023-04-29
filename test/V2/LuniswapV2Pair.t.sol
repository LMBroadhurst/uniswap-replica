// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.19;

import "../mocks/ERC20Mintable.sol";
import "forge-std/Test.sol";
import "../../src/V2/LuniswapV2Pair.sol";

contract LuniswapV2PairTest is Test {

    ERC20Mintable token0;
    ERC20Mintable token1;
    LuniswapV2Pair pair;
    TestUser user;

    function setUp() public {
        user = new TestUser();

        token0 = new ERC20Mintable("Token A", "TKNA");
        token1 = new ERC20Mintable("Token B", "TKNB");
        pair = new LuniswapV2Pair(address(token0), address(token1));

        token0.mint(10 ether, address(this));
        token1.mint(10 ether, address(this));

        token0.mint(10 ether, address(user));
        token1.mint(10 ether, address(user));
    }

    function testMintLPairInit() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint();

        // -1000 for 1% fee?
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);
        assertEq(pair.totalSupply(), 1 ether);
    }

    function testMintOnExistingLPair() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(); // + 1 LP

        vm.warp(37);

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 2 ether);

        pair.mint(); // + 2 LP

        assertEq(pair.balanceOf(address(this)), 3 ether - 1000);
        assertEq(pair.totalSupply(), 3 ether);
        assertReserves(3 ether, 3 ether);
    }

    function testMintUnbalanced() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(); // + 1 LP
        assertEq(pair.balanceOf(address(this)), 1 ether - 1000);
        assertReserves(1 ether, 1 ether);

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(); // + 1 LP
        assertEq(pair.balanceOf(address(this)), 2 ether - 1000);
        assertReserves(3 ether, 2 ether);
    }

    function testBurnUnbalancedDifferentUsers() public {
        user.provideLiquidity(
            address(pair),
            address(token0),
            address(token1),
            1 ether,
            1 ether
        );

        assertEq(pair.balanceOf(address(this)), 0);
        assertEq(pair.balanceOf(address(user)), 1 ether - 1000);
        assertEq(pair.totalSupply(), 1 ether);

        token0.transfer(address(pair), 2 ether);
        token1.transfer(address(pair), 1 ether);

        pair.mint(); // + 1 LP

        pair.burn();

        // this user is penalized for providing unbalanced liquidity
        assertEq(pair.balanceOf(address(this)), 0);
        assertReserves(1.5 ether, 1 ether);
        assertEq(pair.totalSupply(), 1 ether);
        assertEq(token0.balanceOf(address(this)), 10 ether - 0.5 ether);
        assertEq(token1.balanceOf(address(this)), 10 ether);

        user.withdrawLiquidity(address(pair));

        // testUser receives the amount collected from this user
        assertEq(pair.balanceOf(address(user)), 0);
        assertReserves(1500, 1000);
        assertEq(pair.totalSupply(), 1000);
        assertEq(
            token0.balanceOf(address(user)),
            10 ether + 0.5 ether - 1500
        );
        assertEq(token1.balanceOf(address(user)), 10 ether - 1000);
    }

    function testBurnZeroTotalSupply() public {
        // 0x12; If you divide or modulo by zero.
        vm.expectRevert(
            hex"4e487b710000000000000000000000000000000000000000000000000000000000000012"
        );
        pair.burn();
    }

    function testBurnZeroLiquidity() public {
        // Transfer and mint as a normal user.
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 1 ether);
        pair.mint();

        // Burn as a user who hasn't provided liquidity.
        bytes memory prankData = abi.encodeWithSignature("burn()");

        vm.prank(address(0xdeadbeef));
        vm.expectRevert(bytes(hex"749383ad")); // InsufficientLiquidityBurned()
        pair.burn();
    }

    function testReservesPacking() public {
        token0.transfer(address(pair), 1 ether);
        token1.transfer(address(pair), 2 ether);
        pair.mint();

        bytes32 val = vm.load(address(pair), bytes32(uint256(8)));
        assertEq(
            val,
            hex"000000000000000000001bc16d674ec800000000000000000de0b6b3a7640000"
        );
    }


    // -- HELPERS -- //

    function assertReserves(uint112 expectedReserve0, uint112 expectedReserve1)
        internal
    {
        (uint128 reservesToken0, uint128 reservesToken1, ) = pair.getReserves();
        assertEq(reservesToken0, expectedReserve0, "unexpected reserve0");
        assertEq(reservesToken1, expectedReserve1, "unexpected reserve1");
    }
}

contract TestUser {
    function provideLiquidity(
        address pairAddress_,
        address token0Address_,
        address token1Address_,
        uint256 amount0_,
        uint256 amount1_
    ) public {
        ERC20(token0Address_).transfer(pairAddress_, amount0_);
        ERC20(token1Address_).transfer(pairAddress_, amount1_);

        LuniswapV2Pair(pairAddress_).mint();
    }

    function withdrawLiquidity(address pairAddress_) public {
        LuniswapV2Pair(pairAddress_).burn();
    }
}