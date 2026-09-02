// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice A hook whose creatorOf always reverts. Used to prove the registry
///         fails closed: if the authority it defers to cannot answer, no
///         MetadataSet event is emitted for anyone.
contract RevertingHook {
    function creatorOf(address) external pure returns (address) {
        revert("hook is down");
    }
}
