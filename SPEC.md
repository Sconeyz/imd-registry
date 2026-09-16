# CoinMetadataRegistry — specification

## 1. What this is

A registry in which the creator of a launchpad coin publishes one metadata
document for that coin. The record is the contract's event log and nothing
else: the contract keeps no metadata storage, has no owner, no pause, no
upgrade path and charges no fee. A write is one transaction that emits one
event; a reader takes the latest event per coin.

## 2. Contract facts

| Field | Value |
|---|---|
| Chain | Ethereum mainnet (chain id 1) |
| Address | `0xbf214a6274b747670e2E30039101F1D4b0Eff3C2` |
| Deploy block | `25886424` |
| Launchpad hook (constructor argument, `HOOK()`) | `0x51768F5dA32BA2008304cC81674da51aCb802888` |
| Event | `event MetadataSet(address indexed coin, address indexed creator, string uri)` |
| Indexed parameters | `coin` (topic 1), `creator` (topic 2); `uri` is in the data |
| topic0 = `keccak256("MetadataSet(address,address,string)")` | `0xedcaa71483243d7a5ca5e6114a75dd37a9a11c7d8c8ba9360a403d71300365e4` |
| Write function | `function setMetadata(address coin, string calldata uri) external` |
| Selector = `keccak256("setMetadata(address,string)")[0:4]` | `0x4fbffc93` |

Source: `src/CoinMetadataRegistry.sol`. Deployment record: `DEPLOYMENT.md`.

## 3. Who can write

`setMetadata(coin, uri)` succeeds only when

```solidity
msg.sender == HOOK.creatorOf(coin)
```

where `HOOK` is the launchpad hook fixed at construction and
`creatorOf(address) view returns (address)` is that hook's public creator
lookup. Any other sender reverts with `"not creator"`. On success the
contract emits `MetadataSet(coin, msg.sender, uri)` and does nothing else.

The contract does not check:

- the format of `uri` (any string, including the empty string, is accepted);
- the length of `uri` (bounded only by gas);
- the content of `uri`;
- whether a document was already set for the coin (every call emits a new event);
- anything about `coin` beyond what `creatorOf(coin)` returns.

## 4. How to read

The record is read off-chain from event logs. One JSON-RPC call can return
every document ever set:

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "eth_getLogs",
  "params": [{
    "address": "0xbf214a6274b747670e2E30039101F1D4b0Eff3C2",
    "topics": ["0xedcaa71483243d7a5ca5e6114a75dd37a9a11c7d8c8ba9360a403d71300365e4"],
    "fromBlock": "0x18afed8",
    "toBlock": "latest"
  }]
}
```

`0x18afed8` is the deploy block, 25886424. Each returned log carries the
coin in `topics[1]`, the creator in `topics[2]` and the ABI-encoded `uri`
string in `data`. Some providers cap the block span of one `eth_getLogs`
call; if a call is rejected, split the range and merge the results.

Two rules turn the logs into the current document per coin:

1. **The latest `MetadataSet` for a coin wins.** Order the coin's logs by
   `blockNumber` ascending, then `logIndex` ascending; the last one is
   current. Both fields are on every log, and `logIndex` is unique within a
   block, so the order is total. A log with `removed: true` (a reorg
   notification) is skipped.
2. **An empty `uri` means cleared, not unclaimed.** A coin with no
   `MetadataSet` log has never been written to. A coin whose latest log
   carries `uri == ""` was written to and then cleared. These are different
   facts and a reader must not collapse them.

This is an events-only design. Nothing is stored in contract state, so
other smart contracts cannot read the registry; only off-chain readers with
access to the event log can.

## 5. Document format v1

The `uri` is a document. Version 1 is a JSON object with these members:

| Field | Type | Required | Meaning |
|---|---|---|---|
| `v` | number, `1` | written by every conforming writer | format version |
| `name` | string | optional | display name |
| `description` | string | optional | free text |
| `website` | string | optional | URL |
| `x` | string | optional | X (Twitter) handle or URL |
| `telegram` | string | optional | Telegram handle or URL |
| `image` | string | optional | image URL |

- A field that is absent is absent; a writer omits empty fields rather than
  writing `""`.
- Unknown members are ignored by readers.
- `symbol` is deliberately not a field: the coin's symbol is already on
  chain in the ERC-20 contract, and the document must not contradict it.

Recommended encoding: inline, as

```
data:application/json,<percent-encoded JSON>
```

where the JSON is `JSON.stringify` output and percent-encoding is applied to
exactly `%`, `#`, U+0000–U+001F and U+007F (`%25`, `%23`, `%00`–`%1F`,
`%7F`). Everything else, including non-ASCII, is written raw.

A `uri` may instead point to a document by another scheme (for example
`ipfs://` or `https://`); format v1 does not define fetching, and a reader
decides for itself whether to fetch.

### Behaviour of the reader at https://idmd-reader.pages.dev (not part of the format)

It percent-decodes the inline payload, so a `%` that is not a valid
percent-sequence makes the document unparseable. It also accepts the
`data:application/json;base64,` form and tolerates a `;charset=` parameter.
It accepts a finite JSON number where a string is expected and displays it
as its decimal string; any other type is shown as present-but-invalid. It
does not reject a document for a missing or different `v`. It does not fetch
non-inline uris: any other scheme or media type is not parsed and is shown
raw.

## 6. Disclosures

**(a) The contract has no opinions.** A `MetadataSet` log proves that the
address the launchpad hook reported as the coin's creator, at the time of
the call, wrote that exact string for that coin. It proves nothing about
whether any statement in the document is true, whether a linked host is
safe, or whether an image or name imitates something else. What a front end
shows, hides, links or renders from a document is that front end's own
decision, not the registry's.

**(b) History dependency.** Because the record is event logs and not
contract storage, reading it depends on access to historical logs from the
deploy block onward. Ethereum's history-expiry work (EIP-4444) allows nodes
to stop serving old history; archive providers retain it. A reader needs a
provider that serves logs back to block 25886424, and should not treat an
empty result as proof that no document was ever set.
