// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {CoinMetadataRegistry} from "../../src/CoinMetadataRegistry.sol";

/// @notice Runs only under --fork-url --fork-block-number 25879520. The fork is
///         an in-memory copy of mainnet state: nothing is deployed to any
///         network and no transaction is signed or sent.
///
///         Chain values below were read FRESH at the pin (2026-09-01):
///         - block 25,879,520, timestamp 2026-09-01T02:43:47Z
///         - COIN taken from the hook's own logs (topic
///           0x83bad9dc00e441f3f6bb4546287f288189a4ab296585f5d7fa2bd686242ca8ed,
///           emitted at block 25,876,689)
///         - CREATOR read via creatorOf(COIN) at the pin, and re-checked
///           in-test rather than trusted from this comment.
contract ForkTest is Test {
    address internal constant HOOK = 0x51768F5dA32BA2008304cC81674da51aCb802888;
    address internal constant COIN = 0x64914921E03069dA66823F84fFcfB9931F05281A;
    uint256 internal constant PIN = 25879520;

    CoinMetadataRegistry internal registry;
    address internal creator;

    string internal constant TYPICAL =
        "{\"name\":\"Meridian Protocol\",\"symbol\":\"MRDN\",\"description\":\"Community-run liquidity routing for long-tail assets. Fair launch, no presale, no team allocation, and 100.0% of liquidity burned in the deploy block.\",\"image\":\"ipfs://QmYwAPJzv5CZsnA625s3Xf2nemtYgPpHdWEz79ojWnPbdG\",\"website\":\"https://meridian.finance\",\"x\":\"https://x.com/meridianfi\",\"telegram\":\"https://t.me/meridianfi\",\"discord\":\"https://discord.gg/mrdn\"}";

    event MetadataSet(address indexed coin, address indexed creator, string uri);

    function setUp() public {
        require(block.number == PIN, "run with --fork-block-number 25879520");
        registry = new CoinMetadataRegistry(HOOK);
        // Read the creator from the chain at the pin — not hardcoded.
        creator = CoinMetadataRegistry(registry).HOOK().creatorOf(COIN);
        require(creator != address(0), "picked coin has no creator at pin");
    }

    function test_fork_realCreatorSets() public {
        vm.expectEmit(true, true, true, true, address(registry));
        emit MetadataSet(COIN, creator, TYPICAL);
        vm.prank(creator);
        registry.setMetadata(COIN, TYPICAL);
    }

    function test_fork_randomAddressReverts() public {
        address rando = address(0x1111111111111111111111111111111111111111);
        require(rando != creator, "collision");
        vm.prank(rando);
        vm.expectRevert(bytes("not creator"));
        registry.setMetadata(COIN, TYPICAL);
    }

    /// Execution-gas measurement for a typical call against the REAL hook,
    /// comparable to the prior artifact's `event/typical` row (exec 11939).
    /// The registry account is warmed first, exactly as the prior run did —
    /// cold-account surcharges belong to the calldata/intrinsic layer of the
    /// comparison, not the frame.
    function test_fork_gas_typical() public {
        address r = address(registry);
        assembly {
            pop(extcodesize(r))
        }
        vm.prank(creator);
        registry.setMetadata(COIN, TYPICAL);
    }
}
