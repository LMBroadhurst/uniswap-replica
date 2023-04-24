# Foundry x Hardhat

foundry: https://book.getfoundry.sh/
hh: https://hardhat.org/

## Forge

### Basic Commands

```
$ forge --help - Show the forge help message

$ foo --help - Show the help message for a specific command

$ forge build - Build the project, compiling all sol files

$ forge test - Run the test suite
```

### Installing & Updating Dependencies
To add a dependency, run `forge install`.
Note that this is often of complete GitHub repos, as shown in the example below.

```
$ forge install transmissions11/solmate
```

You can update a specific dependency to the latest commit on the version you have specified using forge update <dep>

```
$ forge update lib/solmate
```

### Exisiting Projects
e.g. Downloading a codebase for an audit
When cloning an existing forge project, you can run `forge install` to install all the submodule dependencies in the project.

### Remapping Dependencies

Forge can remap dependencies to make them easier to import. Forge will automatically try to deduce some remappings for you:

```
$ forge remappings
ds-test/=lib/forge-std/lib/ds-test/src/
forge-std/=lib/forge-std/src/
```

These remappings mean:

To import from forge-std we would write: import "forge-std/Contract.sol";
To import from ds-test we would write: import "ds-test/Contract.sol";

### Hardhat compatibility
Forge also supports Hardhat-style projects where dependencies are npm packages (stored in node_modules) and contracts are stored in contracts as opposed to src.

To enable Hardhat compatibility mode pass the --hh flag.

foundry docs: https://book.getfoundry.sh/config/hardhat
hh docs: https://hardhat.org/hardhat-runner/docs/advanced/hardhat-and-foundry

## Deploying and Testing

### Deploying

Forge can deploy smart contracts to a given network with the forge create command.

To deploy a contract, you must provide a RPC URL (env: ETH_RPC_URL) and the private key of the account that will deploy the contract.

To deploy MyContract to a network:
```
$ forge create --rpc-url <your_rpc_url> --private-key <your_private_key> src/MyContract.sol:MyContract
compiling...
success.
Deployer: 0xa735b3c25f...
Deployed to: 0x4054415432...
Transaction hash: 0x6b4e0ff93a...
```

Use the --constructor-args flag to pass arguments to the constructor:
```
$ forge create --rpc-url <your_rpc_url> \
    --constructor-args "ForgeUSD" "FUSD" 18 1000000000000000000000 \
    --private-key <your_private_key> \
    --etherscan-api-key <your_etherscan_api_key> \
    --verify \
    src/MyToken.sol:MyToken
```

### Logs and Traces

The default behavior for forge test is to only display a summary of passing and failing tests. You can control this behavior by increasing the verbosity (using the -v flag). Each level of verbosity adds more information:

- Level 2 (-vv): Logs emitted during tests are also displayed. That includes assertion errors from tests, showing information such as expected vs actual.
- Level 3 (-vvv): Stack traces for failing tests are also displayed.
- Level 4 (-vvvv): Stack traces for all tests are displayed, and setup traces for failing tests are displayed.
- Level 5 (-vvvvv): Stack traces and setup traces are always displayed.