// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {CoinMetadataRegistry} from "../../src/CoinMetadataRegistry.sol";

/// @notice Length-cap analysis: setMetadata against the REAL hook across uri
///         sizes 100 B / 1 KB / 10 KB / 100 KB. Fork-only, same pin as
///         Fork.t.sol. Payloads are all-nonzero ASCII — realistic for JSON or
///         URI metadata, and the worst case for calldata pricing, so the curve
///         reported from these figures is an upper bound per byte.
contract LengthCapTest is Test {
    address internal constant HOOK = 0x51768F5dA32BA2008304cC81674da51aCb802888;
    address internal constant COIN = 0x64914921E03069dA66823F84fFcfB9931F05281A;
    uint256 internal constant PIN = 25879520;

    CoinMetadataRegistry internal registry;
    address internal creator;

    function setUp() public {
        require(block.number == PIN, "run with --fork-block-number 25879520");
        registry = new CoinMetadataRegistry(HOOK);
        creator = registry.HOOK().creatorOf(COIN);
        require(creator != address(0), "picked coin has no creator at pin");
    }

    /// Deterministic printable-ASCII payload: bytes 0x21..0x7a, never zero.
    function _payload(uint256 len) internal pure returns (string memory) {
        bytes memory b = new bytes(len);
        for (uint256 i = 0; i < len; i++) {
            b[i] = bytes1(uint8(0x21 + (i % 0x5a)));
        }
        return string(b);
    }

    function _run(uint256 len) internal {
        string memory uri = _payload(len);
        address r = address(registry);
        assembly {
            pop(extcodesize(r))
        }
        vm.prank(creator);
        registry.setMetadata(COIN, uri);
    }

    function test_len_100B() public {
        _run(100);
    }

    function test_len_1KB() public {
        _run(1_000);
    }

    function test_len_10KB() public {
        _run(10_000);
    }

    function test_len_100KB() public {
        _run(100_000);
    }
}
