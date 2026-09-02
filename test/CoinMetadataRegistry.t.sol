// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {Test} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";
import {CoinMetadataRegistry} from "../src/CoinMetadataRegistry.sol";
import {MockHook} from "./mocks/MockHook.sol";
import {RevertingHook} from "./mocks/RevertingHook.sol";

/// @notice A creator that is itself a contract. The design has to survive
///         contract creators (multisigs, smart accounts) — this was a deciding
///         rationale for the on-chain-pointer choice, so it gets its own test.
contract ContractCreator {
    function set(CoinMetadataRegistry reg, address coin, string calldata uri) external {
        reg.setMetadata(coin, uri);
    }
}

contract CoinMetadataRegistryTest is Test {
    MockHook internal hook;
    CoinMetadataRegistry internal registry;

    address internal constant COIN = address(0xC01);
    address internal constant CREATOR = address(0xA11CE);
    address internal constant STRANGER = address(0xB0B);

    event MetadataSet(address indexed coin, address indexed creator, string uri);

    function setUp() public {
        hook = new MockHook();
        registry = new CoinMetadataRegistry(address(hook));
        hook.setCreator(COIN, CREATOR);
    }

    function test_hookIsImmutableConstructorArg() public view {
        assertEq(address(registry.HOOK()), address(hook));
    }

    function test_creatorSets_eventExact() public {
        vm.expectEmit(true, true, true, true, address(registry));
        emit MetadataSet(COIN, CREATOR, "ipfs://QmExample");
        vm.prank(CREATOR);
        registry.setMetadata(COIN, "ipfs://QmExample");
    }

    function test_nonCreatorReverts() public {
        vm.prank(STRANGER);
        vm.expectRevert(bytes("not creator"));
        registry.setMetadata(COIN, "ipfs://QmExample");
    }

    function test_unlaunchedCoinReverts_anyRealCaller() public {
        // creatorOf(unknown) == address(0); no real caller can be address(0),
        // so every real caller fails the equality check.
        address unknownCoin = address(0xDEAD);
        assertEq(hook.creatorOf(unknownCoin), address(0));

        vm.prank(CREATOR);
        vm.expectRevert(bytes("not creator"));
        registry.setMetadata(unknownCoin, "x");

        vm.prank(STRANGER);
        vm.expectRevert(bytes("not creator"));
        registry.setMetadata(unknownCoin, "x");
    }

    function test_resetAllowed_bothEventsInOrder() public {
        vm.recordLogs();
        vm.prank(CREATOR);
        registry.setMetadata(COIN, "v1");
        vm.prank(CREATOR);
        registry.setMetadata(COIN, "v2");

        Vm.Log[] memory logs = vm.getRecordedLogs();
        assertEq(logs.length, 2);
        bytes32 topic0 = keccak256("MetadataSet(address,address,string)");
        for (uint256 i = 0; i < 2; i++) {
            assertEq(logs[i].emitter, address(registry));
            assertEq(logs[i].topics[0], topic0);
            assertEq(address(uint160(uint256(logs[i].topics[1]))), COIN);
            assertEq(address(uint160(uint256(logs[i].topics[2]))), CREATOR);
        }
        assertEq(abi.decode(logs[0].data, (string)), "v1");
        assertEq(abi.decode(logs[1].data, (string)), "v2");
    }

    function test_contractAsCreator() public {
        ContractCreator cc = new ContractCreator();
        address coin = address(0xC02);
        hook.setCreator(coin, address(cc));

        vm.expectEmit(true, true, true, true, address(registry));
        emit MetadataSet(coin, address(cc), "ipfs://QmFromContract");
        cc.set(registry, coin, "ipfs://QmFromContract");

        // And a contract creator still cannot set for a coin it does not own.
        vm.expectRevert(bytes("not creator"));
        cc.set(registry, COIN, "nope");
    }

    function testFuzz_uriContent(string calldata uri) public {
        vm.expectEmit(true, true, true, true, address(registry));
        emit MetadataSet(COIN, CREATOR, uri);
        vm.prank(CREATOR);
        registry.setMetadata(COIN, uri);
    }

    function testFuzz_uriLength(uint16 len, bytes1 fill) public {
        bytes memory b = new bytes(len);
        for (uint256 i = 0; i < len; i++) b[i] = fill;
        string memory uri = string(b);

        vm.expectEmit(true, true, true, true, address(registry));
        emit MetadataSet(COIN, CREATOR, uri);
        vm.prank(CREATOR);
        registry.setMetadata(COIN, uri);
    }

    function testFuzz_nonCreatorAlwaysReverts(address caller, string calldata uri) public {
        vm.assume(caller != CREATOR);
        vm.prank(caller);
        vm.expectRevert(bytes("not creator"));
        registry.setMetadata(COIN, uri);
    }

    /// @notice The hook address is immutable and unverifiable after deploy, so
    ///         the only chance to reject a codeless one is at construction.
    function test_constructorRejectsNonContract() public {
        vm.expectRevert(bytes("hook not a contract"));
        new CoinMetadataRegistry(address(0));

        address eoa = address(0xE0A1);
        assertEq(eoa.code.length, 0);
        vm.expectRevert(bytes("hook not a contract"));
        new CoinMetadataRegistry(eoa);
    }

    /// @notice Hook failure must fail closed: a reverting creatorOf bubbles up
    ///         and no metadata is recorded, rather than being swallowed into a
    ///         permissive path.
    function test_hookRevertPropagates() public {
        RevertingHook broken = new RevertingHook();
        CoinMetadataRegistry brokenRegistry = new CoinMetadataRegistry(address(broken));

        vm.prank(CREATOR);
        vm.expectRevert(bytes("hook is down"));
        brokenRegistry.setMetadata(COIN, "ipfs://QmExample");

        vm.prank(STRANGER);
        vm.expectRevert(bytes("hook is down"));
        brokenRegistry.setMetadata(COIN, "ipfs://QmExample");
    }
}
