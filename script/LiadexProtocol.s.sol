// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {WrappedEther} from "../src/WrappedEther.sol";
import {LiadexERC20} from "../src/LiadexERC20.sol";
import {TradingPair} from "../src/TradingPair.sol";

contract LiadexProtocol is Script {

    function run() public {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        console.log("Deploying weth contract...");
        WrappedEther weth = new WrappedEther();
        console.log("Weth deployed at: ", address(weth));

        console.log("Deploying ldx contract...");
        LiadexERC20 ldx = new LiadexERC20();
        console.log("Ldx deployed at: ", address(ldx));

        console.log("Deploying trading pair contract...");
        TradingPair tp = new TradingPair(address(weth), address(ldx));
        console.log("Trading pair deployed at: ", address(tp));

        vm.stopBroadcast();
    }
}
