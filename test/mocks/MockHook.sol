// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

/// @notice Minimal stand-in for the launchpad hook: a settable
///         coin -> creator mapping behind the same creatorOf signature.
contract MockHook {
    mapping(address => address) internal creators;

    function setCreator(address coin, address creator) external {
        creators[coin] = creator;
    }

    function creatorOf(address coin) external view returns (address) {
        return creators[coin];
    }
}
