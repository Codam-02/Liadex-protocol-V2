// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TradingPair} from "../src/TradingPair.sol";
import {LiadexERC20} from "../src/LiadexERC20.sol";
import {WrappedEther} from "../src/WrappedEther.sol";

/*
    Contracts within these tests are deployed from 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84,
    any special permission granted to the contract deployer such as onlyOwner modifier is
    therefore granted to 0xb4c79daB8f259C7Aee6E5b2Aa729821864227e84
*/

contract TradingPairTest is Test {
    LiadexERC20 public ldx;
    WrappedEther public weth;
    TradingPair public tp;

    address public signer1;

    function setUp() public {
        weth = new WrappedEther();
        ldx = new LiadexERC20();
        tp = new TradingPair(address(weth), address(ldx));

        signer1 = makeAddr("signer1");
        deal(address(weth), signer1, 1000e18);
        deal(address(ldx), signer1, 1000e18);
        startHoax(signer1);
        weth.approve(address(tp), 1000e18);
        ldx.approve(address(tp), 1000e18);
        vm.stopPrank();
    }

    //---------------------------------

    function test_constructor_TokenAddresses() public view {
        address tokenA = tp.getTokenA();
        address tokenB = tp.getTokenB();
        assertEq(tokenA, address(weth));
        assertEq(tokenB, address(ldx));
    }

    function test_addLiquidity_FirstProvision() public {
        startHoax(signer1, 100e18);
        vm.expectEmit(address(tp));
        emit TradingPair.LiquidityAdded(1000, 1000);
        tp.addLiquidity(1000, 1000);
        vm.stopPrank();
        (uint256 reserveA, uint256 reserveB) = tp.getReserves();
        assertEq(reserveA, 1000);
        assertEq(reserveB, 1000);
    }

    function test_addLiquidity_AnyProvision() public {
        startHoax(signer1, 100e18);
        tp.addLiquidity(1000, 1000);

        vm.expectEmit(address(tp));
        emit TradingPair.LiquidityAdded(9999, 9999);
        tp.addLiquidity(9999, 9999);
        vm.stopPrank();
        (uint256 reserveA, uint256 reserveB) = tp.getReserves();
        assertEq(reserveA, 10999);
        assertEq(reserveB, 10999);
    }

    function test_addLiquidity_LiquidityToken() public {
        startHoax(signer1, 10e18);

        tp.addLiquidity(1000, 1000);
        assertEq(tp.balanceOf(signer1), 1000e18);

        tp.addLiquidity(10000, 10000);
        assertEq(tp.balanceOf(signer1), 11000e18);

        vm.stopPrank();
    }

    function test_addLiquidity_K() public {
        startHoax(signer1, 100e18);
        tp.addLiquidity(1000, 1000);

        uint256 oldK = tp.getK();

        tp.addLiquidity(10000, 10000);
        vm.stopPrank();
        uint256 newK = tp.getK();

        assertGe(newK, oldK);
    }

    //---------------------------------

    function test_withdraw_Balances() public {
        startHoax(signer1, 100e18);
        tp.addLiquidity(1000, 1000);

        vm.expectEmit(address(tp));
        emit TradingPair.LiquidityWithdrawn(500, 500);
        tp.withdraw(500, 500);

        (uint256 reserveA, uint256 reserveB) = tp.getReserves();
        assertEq(reserveA, 500);
        assertEq(reserveB, 500);

        assertEq(tp.balanceOf(signer1), 500e18);
    }

    function test_withdraw_ExceedingAmount() public {
        startHoax(signer1, 100e18);
        tp.addLiquidity(1000, 1000);

        vm.expectRevert("User doesn't own enough liquidity pool funds.");
        tp.withdraw(1001, 1001);
    }

    function test_withdraw_K() public {
        startHoax(signer1, 100e18);
        tp.addLiquidity(1000, 1000);

        uint256 oldK = tp.getK();

        tp.withdraw(700, 700);
        vm.stopPrank();

        uint256 newK = tp.getK();

        assertGt(oldK, newK);
    }

    //---------------------------------

    function test_swap_BalancesAB() public {
        startHoax(signer1, 100e18);
        tp.addLiquidity(10e18, 10e18);
        uint256 swapAmount = 5e16;
        uint256 oldWethBalance = weth.balanceOf(signer1);
        uint256 oldLdxBalance = ldx.balanceOf(signer1);

        tp.swap(swapAmount, 0);
        uint256 newWethBalance = weth.balanceOf(signer1);
        uint256 newLdxBalance = ldx.balanceOf(signer1);
        vm.stopPrank();

        assertApproxEqAbs(oldWethBalance - newWethBalance, newLdxBalance - oldLdxBalance, 5e14);
    }

    function test_swap_BalancesBA() public {
        startHoax(signer1, 100e18);
        tp.addLiquidity(10e18, 10e18);
        uint256 swapAmount = 5e16;
        uint256 oldWethBalance = weth.balanceOf(signer1);
        uint256 oldLdxBalance = ldx.balanceOf(signer1);

        tp.swap(0, swapAmount);
        uint256 newWethBalance = weth.balanceOf(signer1);
        uint256 newLdxBalance = ldx.balanceOf(signer1);
        vm.stopPrank();

        assertApproxEqAbs(newWethBalance - oldWethBalance, oldLdxBalance - newLdxBalance, 5e14);
    }

}
