//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {MinimalAccount} from "src/MinimalAccount.sol";
import {Script} from "forge-std/Script.sol";

contract HelperConfig is Script {
    error HelperConfig__ChainNotSupported();

    struct NetworkConfig {
        address entrypoint;
        address account;
    }

    uint256 public constant SEPOLIA_CHAIN_ID = 11155111;
    uint256 public constant ZKSYNC_CHAIN_ID = 300;
    uint256 public constant LOCALHOST_CHAIN_ID = 31337;

    address constant BURNER_WALLET = 0x0Bc7b3Cb8d0c356c30BfDba1B8d32caDDA5429Fc;

    NetworkConfig public activenetworkConfig;

    constructor() {}

    function getActiveNetworkConfig() public view returns (NetworkConfig memory networkConfig) {
        if (block.chainid == SEPOLIA_CHAIN_ID) {
            return getSepoliaEthConfig();
        } else if (block.chainid == ZKSYNC_CHAIN_ID) {
            return getZkSyncConfig();
        } else if (block.chainid == LOCALHOST_CHAIN_ID) {
            return getLocalhostConfig();
        } else {
            revert HelperConfig__ChainNotSupported();
        }
    }

    function getSepoliaEthConfig() public pure returns (NetworkConfig memory networkConfig) {
        NetworkConfig memory sepoliaConfig =
            NetworkConfig({entrypoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789, account: BURNER_WALLET});
        return sepoliaConfig;
    }

    function getZkSyncConfig() public pure returns (NetworkConfig memory networkConfig) {
        NetworkConfig memory zkSyncConfig =
            NetworkConfig({entrypoint: 0x5FF137D4b0FDCD49DcA30c7CF57E578a026d2789, account: BURNER_WALLET});
        return zkSyncConfig;
    }

    function getLocalhostConfig() public pure returns (NetworkConfig memory networkConfig) {
        if (networkConfig.account == address(0)) {}
    }
}

