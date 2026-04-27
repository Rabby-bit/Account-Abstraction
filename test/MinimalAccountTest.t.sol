//SPDX-License-Identifier:MIT

pragma solidity ^0.8.24;

import {HelperConfig} from "script/HelperConfig.s.sol";
import {MinimalAccount} from "src/MinimalAccount.sol";
import {Test, console} from "forge-std/Test.sol";
import {DeployScript} from "script/DeployScript.s.sol";
import {ERC20Mock} from "lib/openzeppelin-contracts/contracts/mocks/token/ERC20Mock.sol";
import {IERC20} from "lib/openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import {SendUserOperation} from "script/SendUserOperation.s.sol";
import {SIG_VALIDATION_FAILED, SIG_VALIDATION_SUCCESS} from "@account-abstraction/core/Helpers.sol";
import {PackedUserOperation} from "@account-abstraction/interfaces/PackedUserOperation.sol";
import {EntryPoint} from "@account-abstraction/core/EntryPoint.sol";
import {IEntryPoint} from "@account-abstraction/interfaces/IEntryPoint.sol";

contract MinimalAccountTest is Test {
    HelperConfig helperConfig;
    MinimalAccount minimalaccount;
    DeployScript deployscript;
    SendUserOperation sendUserOperation;
    HelperConfig.NetworkConfig helperconfig;

    address public constant FOUNDRY_DEFAULT_ADDRESS = 0x1804c8AB1F12E6bbf3894d4083f33e07309d1f38;
    address public constant ANVIL_DEFAULT_ADDRESS = 0xf39Fd6e51aad88F6F4ce6aB8827279cffFb92266;

    function setUp() public {
        helperConfig = new HelperConfig();
        helperconfig = helperConfig.getActiveNetworkConfig();

        vm.prank(helperconfig.account);
        deployscript = new DeployScript();
        (minimalaccount, helperconfig) = deployscript.run();
        sendUserOperation = new SendUserOperation();
    }

    function test__IfOwnerCanCallExecute() public {
        //Arrange
        ERC20Mock usdc = new ERC20Mock();
        bytes memory functionData = abi.encodeWithSelector(usdc.mint.selector, address(usdc), 1);

        //Act
        vm.prank(minimalaccount.owner());
        minimalaccount.execute(address(usdc), 0, functionData);

        //Assert
        uint256 balance = IERC20(address(usdc)).balanceOf(address(usdc));
        assertEq(balance, 1);
    }

    function test__IfItRevertsWhenOwnerIsNotCallingExecute() public {
        //Arrange
        ERC20Mock usdc = new ERC20Mock();
        bytes memory functionData = abi.encodeWithSelector(usdc.mint.selector, address(usdc), 1);
        address randomUser = makeAddr("randomUser");

        //Act
        vm.prank(randomUser);
        vm.expectRevert(MinimalAccount.MinimalAccount__OnlyEntryContractOrOwner.selector);
        minimalaccount.execute(address(usdc), 0, functionData);
    }

    // function test__validateUserOpTest() public {
    //     //Arrange
    //     ERC20Mock usdc = new ERC20Mock();
    //     vm.deal(address(minimalaccount ), 10e18);
    //     address entrypoint = helperconfig.entrypoint;
    //     address account = helperconfig.account;
    //     uint256 missingAccountFunds = 1e18;
    //     uint256 nonce = vm.getNonce(address(minimalaccount));

    //     bytes memory functionData = abi.encodeWithSelector(usdc.mint.selector, address(usdc), 1);
    //     bytes memory callData = abi.encodeWithSelector(minimalaccount.execute.selector,address(usdc),0,functionData);
    //     PackedUserOperation memory userOp = sendUserOperation.generateUserOperation(callData,  helperconfig, address(minimalaccount));

    //     bytes32 userOpHash = IEntryPoint(entrypoint).getUserOpHash(userOp);

    //     // bytes32 userOpHash = entrypoint.getUserOpHash(userOp);
    //     // uint256 missingAccountFunds = 1e18;

    //     //Act
    //     vm.prank(entrypoint);
    //     uint256 validationData = minimalaccount.validateUserOp( userOp,userOpHash,missingAccountFunds);
    //     console.log("owner: ", minimalaccount.owner());
    //     console.log("expected account: ", helperconfig.account);
    //     console.log("validationData: ", validationData);

    //     //Assert
    //     assertEq(validationData, SIG_VALIDATION_SUCCESS);
    // }
}
