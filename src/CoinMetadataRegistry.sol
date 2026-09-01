// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

interface ILaunchpadHook {
    function creatorOf(address coin) external view returns (address);
}

/// @notice On-chain metadata pointer registry for launchpad coins.
///         Events are the entire record: the reader takes latest-event-wins,
///         so there is deliberately no metadata storage, no owner, no pause,
///         and no upgrade path. The hook address is fixed at construction —
///         one registry per factory.
contract CoinMetadataRegistry {
    ILaunchpadHook public immutable HOOK;

    event MetadataSet(address indexed coin, address indexed creator, string uri);

    constructor(address hook) {
        HOOK = ILaunchpadHook(hook);
    }

    function setMetadata(address coin, string calldata uri) external {
        require(msg.sender == HOOK.creatorOf(coin), "not creator");
        emit MetadataSet(coin, msg.sender, uri);
    }
}
