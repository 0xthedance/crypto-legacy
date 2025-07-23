// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {OwnerChangeModule} from "../src/OwnerChangeModule.sol";

contract OwnerChangeModuleTest is Test {
    OwnerChangeModule public counter;

    function setUp() public {
        // counter = new OwnerChangeModule();
    }

    function test_Increment() public {
        counter.increment();
        assertEq(counter.number(), 1);
    }

    function testFuzz_SetNumber(uint256 x) public {
        counter.setNumber(x);
        assertEq(counter.number(), x);
    }
}
