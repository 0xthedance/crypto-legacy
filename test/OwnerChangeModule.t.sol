// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {OwnerChangeModule} from "../src/OwnerChangeModule.sol";
import "safe-contracts/contracts/Safe.sol";
import "safe-contracts/contracts/proxies/SafeProxyFactory.sol";
import "safe-contracts/contracts/libraries/Enum.sol";

contract OwnerChangeModuleTest is Test {
    // Safe contracts
    Safe public safeMasterCopy = Safe(payable(0x41675C099F32341bf84BFc5382aF534df5C7461a)); // 1.4.1 mainnet
    SafeProxyFactory public proxyFactory = SafeProxyFactory(0x4e1DCf7AD4e460CfD30791CCC4F9c8a4f820ec67); // 1.4.1 mainnet

    OwnerChangeModule public ownerChangeModule;
    SafeProxy public safeProxy;

    // Private keys for signing (deterministic)
    uint256 public ownerPrivateKey = 1;
    uint256 public initialOwner1PrivateKey = 2;
    uint256 public initialOwner2PrivateKey = 3;
    
    address public owner = vm.addr(ownerPrivateKey);
    address public heir = address(0x3);
    address public initialOwner1 = vm.addr(initialOwner1PrivateKey);
    address public initialOwner2 = vm.addr(initialOwner2PrivateKey);
    address public stranger = address(0x6);
    uint256 public constant PING_THRESHOLD = 3600; // 1 hour

    function setUp() public {
        deal(owner, 1e24); // Give owner some ether
        // Set up the Safe with initial owners
        address[] memory initialOwners = new address[](3);
        initialOwners[0] = owner;
        initialOwners[1] = initialOwner1;
        initialOwners[2] = initialOwner2;
        uint256 threshold = 1; // Minimum number of signatures required

        vm.startPrank(owner);
        safeProxy = proxyFactory.createProxyWithNonce(address(safeMasterCopy), new bytes(0), uint256(keccak256(abi.encodePacked(owner, block.timestamp))));
        Safe(payable(safeProxy)).setup(
            initialOwners,
            threshold,
            address(0), // to
            new bytes(0), // calldata
            address(0), // fallback handler
            address(0), // payment token
            0, // payment value
            payable(0) // payment receiver
        );

        ownerChangeModule = new OwnerChangeModule(address(safeProxy), owner, heir, PING_THRESHOLD);

        bytes memory enableModuleData = abi.encodeWithSelector(
            Safe(payable(safeProxy)).enableModule.selector,
            ownerChangeModule
        );

        bool success = _executeSafeTransaction(
            0,                      // value
            enableModuleData,      // data
            Enum.Operation.Call     // operation
        );

        require(success, "Failed to enable module");

        // Change the threshold to 2 to allow the heir to replace owners

        bytes memory changeThresholdData = abi.encodeWithSelector(
            Safe(payable(safeProxy)).changeThreshold.selector,
            2
        );

        success = _executeSafeTransaction(
            0,                      // value
            changeThresholdData,    // data
            Enum.Operation.Call     // operation
        );

        require(success, "Failed to change threshold");

        vm.stopPrank();
    }

    // Helper function to execute a Safe transaction
    function _executeSafeTransaction(
        uint256 value,
        bytes memory data,
        Enum.Operation operation
    ) internal returns (bool) {

        // Create the transaction hash
        bytes32 txHash = Safe(payable(safeProxy)).getTransactionHash(
            address(safeProxy),     // to
            value,                      // value
            data,                   // data
            operation,              // operation
            0,                      // safeTxGas
            0,                      // baseGas
            0,                      // gasPrice
            address(0),             // gasToken
            payable(address(0)),    // refundReceiver
            Safe(payable(safeProxy)).nonce()     // nonce
        );
        
        // Create signatures for the transaction
        bytes memory signatures = _createSignatures(txHash);

        bool success = Safe(payable(safeProxy)).execTransaction(
            address(safeProxy),     // to
            value,                      // value
            data,       // data
            Enum.Operation.Call,    // operation
            0,                      // safeTxGas
            0,                      // baseGas
            0,                      // gasPrice
            address(0),             // gasToken
            payable(address(0)),    // refundReceiver
            signatures              // signatures
        );

        return success;

    }

    // Helper function to create signatures for Safe transactions
    function _createSignatures(bytes32 txHash) internal view returns (bytes memory) {
        // Sign the transaction hash with the owner's private key
        (uint8 v1, bytes32 r1, bytes32 s1) = vm.sign(ownerPrivateKey, txHash);
        return abi.encodePacked(r1, s1, v1);
    }

    function testPing() public {
        vm.stopPrank();
        vm.prank(owner); // Simulate the owner calling ping
        ownerChangeModule.ping();
        assertEq(ownerChangeModule.lastPing(), block.timestamp);
        // Check that the Pinged event was emitted
        //vm.expectEmit(true, true, true, true);
        //emit OwnerChangeModule.Pinged(owner, block.timestamp);
    }

    function testOnlyOwnerCanPing() public {
        // Heir cannot ping
        vm.prank(heir);
        vm.expectRevert("Not owner");
        ownerChangeModule.ping();
        
        // Stranger cannot ping
        vm.prank(stranger); 
        vm.expectRevert("Not owner");
        ownerChangeModule.ping();
    }
    
    function testReplaceAllOwnersWhenPingExpires() public {
        vm.prank(owner);
        ownerChangeModule.ping();
        
        // Move time forward to simulate ping expiration
        vm.warp(block.timestamp + PING_THRESHOLD + 1);
        
        // Replace all owners with the heir
        vm.prank(heir); 

        ownerChangeModule.replaceAllOwners();
        
        // Check that the owner is now the heir
        address[] memory owners = Safe(payable(safeProxy)).getOwners();
        assertEq(owners.length, 1);
        assertEq(owners[0], heir);
    }

    function testOnlyHeirCanReplaceOwners() public {
        vm.prank(owner);
        ownerChangeModule.ping();
        
        // Move time forward to simulate ping expiration
        vm.warp(block.timestamp + PING_THRESHOLD + 1);
        

        // Owner cannot replace owners
        vm.prank(owner);
        vm.expectRevert("Not heir");
        ownerChangeModule.replaceAllOwners();
        
        // Stranger cannot replace owners
        vm.prank(stranger);
        vm.expectRevert("Not heir");
        ownerChangeModule.replaceAllOwners();
    }

    function testReplaceAllOwnersWhenPingNotExpired() public {
        vm.prank(owner);
        ownerChangeModule.ping();
        
        // Try to replace owners before ping expires
        vm.prank(heir);
        vm.expectRevert("Ping not expired");
        ownerChangeModule.replaceAllOwners();
    }

}
