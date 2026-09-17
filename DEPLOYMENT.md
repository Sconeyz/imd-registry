# CoinMetadataRegistry — mainnet deployment record

All figures below are `[MEASURED]` — read from Ethereum mainnet by `eth_call` /
receipt queries only. No transaction was sent in producing this record. Each
figure names the block height it was read at.

## Deployment

| Field | Value | |
|---|---|---|
| Network | Ethereum mainnet | |
| Chain id | `1` | [MEASURED] @ 25886431 |
| Contract | `0xbf214a6274b747670e2E30039101F1D4b0Eff3C2` | [MEASURED] @ 25886424 (receipt `contractAddress`) |
| Deployer | `0x8e0B256c53170B7BE5Bc3Eba4C0A665EBa594228` | [MEASURED] @ 25886424 (receipt `from`) |
| Deploy tx | `0xeb3cce3ce5f85e87d244d65e56a409ad61c10630afce8596bcf7b2d5ba2864e2` | |
| Status | `1` (success) | [MEASURED] @ 25886424 |
| Block number | `25886424` | [MEASURED] |
| Block hash | `0xd8716d8ec3b370ef37411463e0d162f5eba7a890e7c1f278e009d444f446fb03` | [MEASURED] @ 25886424 |
| Block timestamp | `1788313775` = **2026-09-02T01:49:35Z** | [MEASURED] @ 25886424 |
| Transaction index | `87` | [MEASURED] @ 25886424 |

## Cost

| Field | Value | |
|---|---|---|
| Gas used | `216461` | [MEASURED] @ 25886424 |
| Effective gas price | `57281547` wei (0.057281547 gwei) | [MEASURED] @ 25886424 |
| Cost | `12399220945167` wei = **0.000012399220945167 ETH** | computed: 216461 x 57281547 |

## Constructor

Single argument, the launchpad hook:

```
hook = 0x51768F5dA32BA2008304cC81674da51aCb802888
```

ABI-encoded tail of the deploy transaction's input, left-padded to 32 bytes
[MEASURED] @ 25886424:

```
0x00000000000000000000000051768f5da32ba2008304cc81674da51acb802888
```

The transaction input is the artifact's creation code (959 bytes) followed by
that one word — 991 bytes total, creation-code prefix byte-identical to
`out/CoinMetadataRegistry.sol/CoinMetadataRegistry.json` `bytecode.object`.

## Source

| Field | Value |
|---|---|
| Commit | `dbd33ec` (`dbd33ec5cb946070cf9716a418d528894d979ed1`, tree `f690ea7df030296e55eb312613c963378118499d`) |
| Commit subject | review fixes: constructor rejects codeless hook; fail-closed test on hook revert; correct forge-std gitignore note (11 unit tests passing) |
| Working tree at record time | clean (`git status --porcelain` empty) |

## Compiler settings

| Setting | `foundry.toml` | Effective (artifact metadata) |
|---|---|---|
| solc | `0.8.26` | `0.8.26+commit.8a97fa7a` |
| optimizer | `true` | `enabled: true` |
| optimizer runs | `200` | `200` |
| via_ir | `false` | `false` |
| evm_version | `prague` | **`cancun`** |

**Use `cancun`, not `prague`, when verifying.** `foundry.toml` requests
`evm_version = "prague"`, but solc 0.8.26 predates prague support and the
compiler settles on `cancun`; the artifact's own metadata records `cancun`, and
a forced rebuild from this exact `foundry.toml` reproduces `cancun` and the
same runtime bytecode. The `prague` line in `foundry.toml` is therefore inert,
not a description of what was built. [MEASURED] by rebuild at commit `dbd33ec`.

## Runtime bytecode

| Field | Value | |
|---|---|---|
| Length | `729` bytes | [MEASURED] @ 25886431 |
| keccak256 | `0x702e78a2894a2f60d520ab210b56c9b25ea786c2f25d29f670ba79dc9d50516d` | [MEASURED] @ 25886431 |

Fingerprint check: the artifact's `deployedBytecode.object` (729 bytes, both
immutable slots all-zero as shipped) with the hook address written into the two
`immutableReferences` offsets — `start 82` and `start 175`, 32 bytes each — is
**byte-identical to the on-chain runtime code**. The 20-byte hook address
occurs in the on-chain code at exactly offsets `94` and `187` (i.e. the
low-order 20 bytes of those two 32-byte slots) and nowhere else.

## Wiring and authorisation — verified by simulation

`eth_call` only; nothing was written. [MEASURED] @ 25886431.

| Check | Result |
|---|---|
| `HOOK()` | `0x51768F5dA32BA2008304cC81674da51aCb802888` — equals the constructor arg |
| `HOOK.creatorOf(0x64914921E03069dA66823F84fFcfB9931F05281A)` | `0xEC7806EF702122b611180d49E2a6787D88C5b866` |
| `setMetadata(coin,"probe")` from that creator | succeeds, empty return (`0x`) |
| `setMetadata(coin,"probe")` from `0x1111…1111` | reverts `Error(string)` = `"not creator"` |

## State

| Field | Value | |
|---|---|---|
| Deployer nonce | `1` | [MEASURED] @ 25886431 |
| Deployer balance | `0.019987600779054833 ETH` | [MEASURED] @ 25886431 |
| `MetadataSet` events | none — `eth_getLogs` over blocks 25886424–25886431 for this address returns empty | [MEASURED] @ 25886431 |

## Verification

Etherscan source verification: NOT YET — deferred to board launch by decision 2026-09-01.
