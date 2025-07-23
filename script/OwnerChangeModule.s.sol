// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";
import {OwnerChangeModule} from "../src/OwnerChangeModule.sol";

contract OwnerChangeModuleScript is Script {
    OwnerChangeModule public ownerChangeModule;
    address public constant SAFE_ADDRESS = vm.envUint("SAFE_ADDRESS"); 
    address public constant OWNER_ADDRESS = vm.envAddress("OWNER_ADDRESS"); 
    address public constant HEIR_ADDRESS = vm.envAddress("HEIR_ADDRESS"); 
    uint256 public constant PING_THRESHOLD = 30 days; // 30 days

    OwnerChangeModule public ownerChangeModule;

    function setUp() public {
        ownerChangeModule = new OwnerChangeModule(SAFE_ADDRESS, OWNER_ADDRESS, HEIR_ADDRESS, PING_THRESHOLD);
    }

    function run() public {
        vm.startBroadcast();

        ownerChangeModule = new OwnerChangeModule();

        vm.stopBroadcast();
    }
}