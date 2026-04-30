//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {IAccount} from "@account-abstraction/interfaces/IAccount.sol";
import {PackedUserOperation} from "@account-abstraction/interfaces/PackedUserOperation.sol";
import {IEntryPoint} from "@account-abstraction/interfaces/IEntryPoint.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "@account-abstraction/core/Helpers.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";
// import {IAccountExecute} from "@account-abstraction/interfaces/IAccountExecute.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {DecentralizedStableCoin} from "src/StableCoin.sol";

contract MinimalAccount is IAccount, Ownable {
    IEntryPoint private immutable entryPoint;
    bytes32 private constant TYPE_HASH =
        keccak256("EIP712Domain(string name,string version,uint256 chainId,address verifyingContract)");

    error MinimalAccount__OnlyEntryContractCanValidate();
    error MinimalAccount__OnlyEntryContractOrOwner();
    error MinimalAccount__ExecutionNotSuccesful();

    modifier onlyEntryCoontract() {
        if (msg.sender != address(entryPoint)) {
            revert MinimalAccount__OnlyEntryContractCanValidate();
        }
        _;
    }

    modifier onlyEntryContractOrOwner() {
        if (msg.sender != address(entryPoint) && msg.sender != owner()) {
            revert MinimalAccount__OnlyEntryContractOrOwner();
        }
        _;
    }

    constructor(address _entryPoint) Ownable(msg.sender) {
        entryPoint = IEntryPoint(_entryPoint);
    }

    function validateUserOp(PackedUserOperation calldata userOp, bytes32 userOpHash, uint256 missingAccountFunds)
        external
        onlyEntryCoontract
        returns (uint256 validationData)
    {
        validationData = _validateSignature(userOp, userOpHash);
        if (missingAccountFunds > 0) {
            (bool success,) = payable(msg.sender).call{value: missingAccountFunds}("");
            require(success);
        }
        if (validationData != SIG_VALIDATION_SUCCESS) {
            return validationData;
        }

        return validationData;
    }

    function _validateSignature(PackedUserOperation memory userOp, bytes32 userOpHash)
        internal
        view
        returns (uint256 validationData)
    {
        address signer = ECDSA.recover(userOpHash, userOp.signature);

        if (signer == address(0) || signer != owner()) {
            return SIG_VALIDATION_FAILED;
        }

        return SIG_VALIDATION_SUCCESS;
    }

    function execute(address dest, uint256 value, bytes calldata func) external onlyEntryContractOrOwner {
        (bool success,) = dest.call{value: value}(func);
        require(success);
    }

    receive() external payable {}
}
