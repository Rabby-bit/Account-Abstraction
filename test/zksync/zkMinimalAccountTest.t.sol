//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {Test, console} from "forge-std/Test.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {zkMinimalAccount} from "src/zkMinimalAccount.sol";
import {Transaction, MemoryTransactionHelper} from "@foundry-era-contracts/libraries/MemoryTransactionHelper.sol";
import {ECDSA} from "lib/openzeppelin-contracts/contracts/utils/cryptography/ECDSA.sol";
import {MessageHashUtils} from "lib/openzeppelin-contracts/contracts/utils/cryptography/MessageHashUtils.sol";

contract zkMinimalAccountTest is Test {
    zkMinimalAccount miniAccount;
    ERC20Mock usdc;
    uint256 public constant DEFAULT_ANVIL_PRIVATE_KEY =
        0xac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80;
    bytes32 constant EMPTY_BYTES = bytes32(0);
    address public constant ANVIL_DEFAULT_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {
        miniAccount = new zkMinimalAccount();
        miniAccount.transferOwnership(ANVIL_DEFAULT_ADDRESS);
        usdc = new ERC20Mock();
        vm.deal(address(miniAccount), 3e18 ether);
    }

    function test__OwnerCanExecute() public {
        //arrange
        address dest = address(usdc);
        bytes memory functionData = abi.encodeWithSelector(usdc.mint.selector, address(usdc), 1);
        uint256 value = 0;
        uint256 to = uint256(uint160(address(miniAccount.owner())));

        Transaction memory _transaction = unSignedTransaction(113, to, uint256(uint160(dest)), value, functionData);

        //act
        vm.prank(miniAccount.owner());
        miniAccount.executeTransaction(EMPTY_BYTES, EMPTY_BYTES, _transaction);
    }

    function unSignedTransaction(uint256 txType, uint256 from, uint256 to, uint256 value, bytes memory data)
        public
        returns (Transaction memory)
    {
        uint256 nonce = vm.getNonce(address((uint160(from))));
        return Transaction({
            txType: txType,
            from: from,
            to: to,
            gasLimit: 16777716,
            gasPerPubdataByteLimit: 16777716,
            maxFeePerGas: 16777716,
            maxPriorityFeePerGas: 16777716,
            paymaster: uint256(0),
            nonce: nonce,
            value: value,
            reserved: [uint256(0), uint256(0), uint256(0), uint256(0)],
            data: data,
            signature: hex"",
            factoryDeps: new bytes32[](0),
            paymasterInput: hex"",
            reservedDynamic: hex""
        });
    }

    function signedTransaction(Transaction memory _transaction) public returns (Transaction memory) {
        bytes32 unsignedTransactionHash = MemoryTransactionHelper.encodeHash(_transaction);

        bytes32 digest = MessageHashUtils.toEthSignedMessageHash(unsignedTransactionHash);

        uint8 v;
        bytes32 r;
        bytes32 s;
        (v, r, s) = vm.sign(DEFAULT_ANVIL_PRIVATE_KEY, digest);

        Transaction memory signedTransaction = _transaction;
        signedTransaction.signature = abi.encodePacked(r, s, v);
        return signedTransaction;
    }
}
