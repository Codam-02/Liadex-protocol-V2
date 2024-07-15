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

}
