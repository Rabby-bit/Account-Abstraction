//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {MinimalAccount} from "src/MinimalAccount.sol";
import {Script} from "forge-std/Script.sol";
import {PackedUserOperation} from "@account-abstraction/interfaces/PackedUserOperation.sol";
import {HelperConfig} from "script/HelperConfig.s.sol";
import {EntryPoint} from "@account-abstraction/core/EntryPoint.sol";
import {IEntryPoint} from "@account-abstraction/interfaces/IEntryPoint.sol";

contract SendUserOperation is Script {
    uint256 public constant LOCALHOST_CHAIN_ID = 31337;
    uint256 public constant DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    function run() public {}

    function generateUserOperation(bytes memory callData, HelperConfig.NetworkConfig memory config, address account)
        public
        view
        returns (PackedUserOperation memory)
    {
        uint256 nonce = vm.getNonce(account) - 1;
        address entrypoint = config.entrypoint;
        //Generate unsign
        PackedUserOperation memory userOp = _generateUnSignedOperation(callData, nonce, account);
        bytes32 userOpHash = IEntryPoint(entrypoint).getUserOpHash(userOp);
        uint8 v;
        bytes32 r;
        bytes32 s;
        if (block.chainid == LOCALHOST_CHAIN_ID) {
            (v, r, s) = vm.sign(DEFAULT_ANVIL_PRIVATE_KEY, userOpHash);
        } else {
            (v, r, s) = vm.sign(config.account, userOpHash);
        }

        bytes memory signature = abi.encodePacked(r, s, v);

        userOp.signature = signature;

        return userOp;
    }

    function _generateUnSignedOperation(bytes memory callData, uint256 nonce, address account)
        internal
        pure
        returns (PackedUserOperation memory packedUserOp)
    {
        //uint128(verificationGasLimit) || uint128(callGasLimit)`
        uint128 verificationGasLimit = 16777716;
        uint128 callGasLimit = 16777716;
        //gasFees = `uint128(maxPriorityFeePerGas) || uint128(maxFeePerGas)
        uint128 maxPriorityFeePerGas = 16777716;
        uint128 maxFeePerGas = 16777716;

        uint256 preVerificationGas = 1677777716;
        return packedUserOp = PackedUserOperation({
            sender: account,
            nonce: nonce,
            initCode: hex"",
            callData: callData,
            accountGasLimits: bytes32((uint256(verificationGasLimit) << 128) | uint256(callGasLimit)),
            preVerificationGas: preVerificationGas,
            gasFees: bytes32((uint256(maxPriorityFeePerGas) << 128) | uint256(maxFeePerGas)),
            paymasterAndData: hex"",
            signature: hex""
        });
    }
}
