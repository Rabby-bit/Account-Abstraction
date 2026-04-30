//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {HelperConfig} from "script/HelperConfig.s.sol";
import {Script} from "forge-std/Script.sol";
import {MinimalAccount} from "src/MinimalAccount.sol";

contract DeployScript is Script {
    HelperConfig helperConfig = new HelperConfig();

    function run() public returns (MinimalAccount, HelperConfig.NetworkConfig memory) {
        HelperConfig.NetworkConfig memory activeNetworkConfig = helperConfig.getActiveNetworkConfig();

        vm.startBroadcast(activeNetworkConfig.account);
        MinimalAccount minimalAccount = new MinimalAccount(activeNetworkConfig.entrypoint);
        // if (minimalAccount.owner() != msg.sender) {
        //     minimalAccount.transferOwnership(msg.sender);
        // }
        vm.stopBroadcast();

        return (minimalAccount, activeNetworkConfig);
    }
}
