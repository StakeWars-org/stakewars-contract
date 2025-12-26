// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script} from "forge-std/Script.sol";
import {Stakewars} from "../src/Stakewars.sol";

contract StakewarsScript is Script {
    Stakewars public stakewars;

    function setUp() public {}

    function run() public {
        vm.startBroadcast();

        stakewars = new Stakewars();

        vm.stopBroadcast();
    }
}
