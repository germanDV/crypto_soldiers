## Cost

`forge test --gas-report`

More info: https://book.getfoundry.sh/forge/gas-reports

## Deploy with Verification

```shell
forge create --rpc-url <your_rpc_url> \\
    --constructor-args "ForgeUSD" "FUSD" 18 1000000000000000000000 \\
    --private-key <your_private_key> src/MyToken.sol:MyToken \\
    --etherscan-api-key <your_etherscan_api_key> \\
    --verify
```

What is the Etherscan API Key? Does it show up as verified in etherscan if I create an account?

## Testing With External Test Suites

- standard audited implementation with tests: https://github.com/nibbstack/erc721
- validator: https://erc721validator.org/ & https://github.com/nibbstack/erc721-validator
- tests by some dev in etherexchange: https://github.com/AnAllergyToAnalogy/ERC721/blob/master/tests/Token.test.js

## Foundry

**Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**

Foundry consists of:

-   **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
-   **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
-   **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
-   **Chisel**: Fast, utilitarian, and verbose solidity REPL.

## Documentation

https://book.getfoundry.sh/

## Usage

### Build

```shell
$ forge build
```

### Test

```shell
$ forge test
```

### Format

```shell
$ forge fmt
```

### Gas Snapshots

```shell
$ forge snapshot
```

### Anvil

```shell
$ anvil
```

### Deploy

```shell
$ forge script script/Counter.s.sol:CounterScript --rpc-url <your_rpc_url> --private-key <your_private_key>
```

### Cast

```shell
$ cast <subcommand>
```

### Help

```shell
$ forge --help
$ anvil --help
$ cast --help
```
