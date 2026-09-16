# CoinMetadataRegistry

A registry where a launchpad coin's creator publishes one metadata
document for that coin. Events only: no storage, no owner, no fees.

- Specification: [SPEC.md](SPEC.md)
- Deployment record (address, block, compiler settings): [DEPLOYMENT.md](DEPLOYMENT.md)
- Contract: [src/CoinMetadataRegistry.sol](src/CoinMetadataRegistry.sol)

Deployed on Ethereum mainnet at
`0xbf214a6274b747670e2E30039101F1D4b0Eff3C2`.
A reader for it runs at https://idmd-reader.pages.dev.

## Reproduce the deployed bytecode

    forge build src/CoinMetadataRegistry.sol

No dependencies are needed: the contract has no imports, and
`remappings.txt` pins the compiler metadata. Built with forge 1.5.1 and
solc 0.8.26, this reproduces the deployed runtime including its metadata
hash (immutable slots aside — see DEPLOYMENT.md).

Running the tests (`forge build` / `forge test` with no path) needs
forge-std v1.16.2 at `lib/forge-std`.
