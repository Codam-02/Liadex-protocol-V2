// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {TradingPair} from "../src/TradingPair.sol";
import {LiadexERC20} from "../src/LiadexERC20.sol";
import {WrappedEther} from "../src/WrappedEther.sol";

contract CounterTest is Test {
    TradingPair public tp;

    function setUp() public {
        LiadexERC20 ldx = new LiadexERC20();
        WrappedEther weth = new WrappedEther();

        tp = new TradingPair(ldx.address, weth.address);
    }

}
