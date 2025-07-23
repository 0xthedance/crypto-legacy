// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.0;
// Imports will be added here

import "@safe-global/safe-contracts/contracts/common/Enum.sol";
import "@safe-global/safe-contracts/contracts/Safe.sol";

contract OwnerChangeModule {
    // State variables will be added here
    /**
     * @dev Replace all owners with a new set of owners
     * @param safe Address of the Safe wallet
     * @param owner Address of the owner of the will who can trigger the ping
      * @param heir Address of the heir who can trigger the change
     */
    address public immutable safe;
    address public immutable owner;
    address public immutable heir;
    uint256 public lastPing;
    uint256 public immutable PING_THRESHOLD;

    /**
     * @dev Constructor to initialize the contract with the Safe address, owner, heir, and ping threshold
     * @param _safe Address of the Safe wallet
     * @param _owner Address of the owner of the will
     * @param _heir Address of the heir
     * @param _pingThreshold Time in seconds after which the ping is considered expired
     */
    constructor(address _safe, address _owner, address _heir, uint256 _pingThreshold) {
        safe = _safe;
        owner = _owner;
        heir = _heir;
        PING_THRESHOLD = _pingThreshold;
    }

    modifier onlyHeir() {
        require(msg.sender == heir, "Not heir");
        _;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not owner");
        _;
    }

    function ping() external onlyOwner {
        lastPing = block.timestamp;
    }

    /**
     * @param newOwner new owner address
     */
    function replaceAllOwners() external onlyHeir {
        require(lastPing + PING_THRESHOLD < block.timestamp, "Ping not expired");

        address[] memory oldOwners = Safe(payable(safe)).getOwners();

        // Set threshold to 1
        bytes memory thresholdData = abi.encodeWithSignature("changeThreshold(uint256)", 1);

        require(
            Safe(payable(safe)).execTransactionFromModule(safe, 0, thresholdData, Enum.Operation.Call),
            "Could not change the threshold"
        );

        // Remove all current owners except the last one
        for (uint256 i = 1; i < oldOwners.length; i++) {
            bytes memory removeData = abi.encodeWithSignature(
                "removeOwner(address,address,uint256)",
                oldOwners[0],
                oldOwners[i],
                1 // Keep threshold at 1 during transition
            );

            require(
                Safe(payable(safe)).execTransactionFromModule(safe, 0, removeData, Enum.Operation.Call),
                "Could not remove owner"
            );
        }

        // Replace the last owner with the new owner
        bytes memory swapData = abi.encodeWithSignature(
            "swapOwner(address,address,address)",
            address(0x1), // SENTINEL_OWNERS
            oldOwners[0],
            newOwner
        );

        require(
            Safe(payable(safe)).execTransactionFromModule(safe, 0, swapData, Enum.Operation.Call),
            "Could not swap owner"
        );
    }
}
