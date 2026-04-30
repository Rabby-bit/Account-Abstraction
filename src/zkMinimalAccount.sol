//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;
import {IAccount} from "@foundry-era-contracts/interfaces/IAccount.sol";
import {MemoryTransactionHelper} from "@foundry-era-contracts/libraries/MemoryTransactionHelper.sol";
import {Transaction} from "@foundry-era-contracts/libraries/MemoryTransactionHelper.sol";
import {SystemContractsCaller} from "@foundry-era-contracts/libraries/SystemContractsCaller.sol";
import {Utils} from "@foundry-era-contracts/libraries/Utils.sol";
import {NonceHolder} from "@foundry-era-contracts/NonceHolder.sol";
import {INonceHolder} from "@foundry-era-contracts/interfaces/INonceHolder.sol";
import {
    NONCE_HOLDER_SYSTEM_CONTRACT,
    BOOTLOADER_FORMAL_ADDRESS,
    DEPLOYER_SYSTEM_CONTRACT
} from "@foundry-era-contracts/Constants.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {Ownable} from "lib/openzeppelin-contracts/contracts/access/Ownable.sol";

contract zkMinimalAccount is IAccount, Ownable {
    bytes4 constant ACCOUNT_VALIDATION_SUCCESS_MAGIC = IAccount.validateTransaction.selector;
    using MemoryTransactionHelper for Transaction;

    error zkMinimalAccount__NotEnoughBalance();
    error zkMinimalAccount__OnlyBootLoaderCanCall();
    error zkMinimalAccount__ExecutionFailer();
    error zkMinimalAccount__OnlyBootLoaderandOwnerCanCall();
    error zkMinimalAccount__PayForTranscationFailed();
    error zkMinimalAccount__ExecuteTransactionFromeOutsideFailed();

    constructor() Ownable(msg.sender) {}

    modifier onlyFromBootLoader() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS) {
            revert zkMinimalAccount__OnlyBootLoaderCanCall();
        }
        _;
    }

    modifier onlyFromBootLoaderandOwner() {
        if (msg.sender != BOOTLOADER_FORMAL_ADDRESS && msg.sender != owner()) {
            revert zkMinimalAccount__OnlyBootLoaderandOwnerCanCall();
        }
        _;
    }

    function validateTransaction(
        bytes32,
        /*_txHash*/
        bytes32,
        /*_suggestedSignedHash*/
        Transaction calldata _transaction
    )
        external
        payable
        onlyFromBootLoader
        returns (bytes4 magic)
    {
        return _validateTransaction(_transaction);
    }

    function executeTransaction(
        bytes32,
        /*_txHash*/
        bytes32,
        /*_suggestedSignedHash*/
        Transaction calldata _transaction
    )
        external
        payable
        onlyFromBootLoaderandOwner
    {
        _executeTransaction(_transaction);
    }

    // There is no point in providing possible signed hash in the `executeTransactionFromOutside` method,
    // since it typically should not be trusted.
    function executeTransactionFromOutside(Transaction calldata _transaction) external payable {
        bytes4 magic = _validateTransaction(_transaction);

        if (magic == bytes4(0)) {
            revert zkMinimalAccount__ExecuteTransactionFromeOutsideFailed();
        }
        _executeTransaction(_transaction);
    }

    function payForTransaction(
        bytes32,
        /*_txHash*/
        bytes32,
        /*_suggestedSignedHash*/
        Transaction calldata _transaction
    )
        external
        payable
    {
        bool success = _transaction.payToTheBootloader();

        if (!success) {
            revert zkMinimalAccount__PayForTranscationFailed();
        }
    }

    function prepareForPaymaster(bytes32 _txHash, bytes32 _possibleSignedHash, Transaction calldata _transaction)
        external
        payable {}

    /////Internal functions //////
    function _validateTransaction(Transaction calldata _transaction) internal returns (bytes4 magic) {
        SystemContractsCaller.systemCallWithPropagatedRevert(
            uint32(gasleft()),
            address(NONCE_HOLDER_SYSTEM_CONTRACT),
            0,
            abi.encodeCall(INonceHolder.incrementMinNonceIfEquals, (_transaction.nonce))
        );
        uint256 totalRequiredBalance = _transaction.totalRequiredBalance();
        if (totalRequiredBalance > address(this).balance) {
            revert zkMinimalAccount__NotEnoughBalance();
        }
        bytes32 txHash = _transaction.encodeHash();
        bytes memory signature = _transaction.signature;
        address signer = ECDSA.recover(txHash, signature);

        bool isValidSigner = signer == owner();

        if (isValidSigner) {
            magic = ACCOUNT_VALIDATION_SUCCESS_MAGIC;
        } else {
            magic = bytes4(0);
        }

        return magic;
    }

    function _executeTransaction(Transaction calldata _transaction) internal {
        address to = address(uint160(_transaction.to));
        uint256 value = _transaction.value;
        bytes memory data = _transaction.data;

        SystemContractsCaller.systemCallWithPropagatedRevert(uint32(gasleft()), to, 0, data);

        bool success;

        assembly {
            success := call(gas(), to, value, add(data, 0x20), mload(data), 0, 0)
        }

        if (!success) {
            revert zkMinimalAccount__ExecutionFailer();
        }
    }

    receive() external payable {}
}
