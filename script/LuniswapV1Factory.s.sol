//// SPDX-License-Identifier: UNLICENSED
//pragma solidity 0.8.19;
//
//import "forge-std/Script.sol";
//import "../src/V1/Factory.sol";
//
//contract MyScript is Script {
//    function run() external {
//        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//
//        vm.startBroadcast(deployerPrivateKey);
//        Factory factory = new Factory();
//        vm.stopBroadcast();
//    }
//}
