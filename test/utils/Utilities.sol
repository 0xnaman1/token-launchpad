// SPDX-License-Identifier: Unlicense
pragma solidity >=0.8.0;

import {Test, console} from "forge-std/Test.sol";
import {Vm} from "forge-std/Vm.sol";

//common utilities for forge tests
contract Utilities is Test {
    bytes32 internal nextUser = keccak256(abi.encodePacked("user address"));

    function getNextPrivateKey() internal returns (bytes32) {
        // Pseudo-random private key generation
        bytes32 privateKey = keccak256(abi.encodePacked(nextUser));
        nextUser = keccak256(abi.encodePacked(privateKey));
        return privateKey;
    }

    function getNextUserAddress() external returns (address payable) {
        // Derive address from pseudo-random private key
        bytes32 privateKey = getNextPrivateKey();
        address payable user = payable(vm.addr(uint256(privateKey)));
        return user;
    }

    //create users with 100 ether balance
    function createUsers(
        uint256 userNum
    ) external returns (address payable[] memory, bytes32[] memory) {
        address payable[] memory users = new address payable[](userNum);
        bytes32[] memory privateKeys = new bytes32[](userNum);

        for (uint256 i = 0; i < userNum; i++) {
            bytes32 privateKey = getNextPrivateKey();
            address payable user = payable(vm.addr(uint256(privateKey)));
            vm.deal(user, 100 ether);
            users[i] = user;
            privateKeys[i] = privateKey;
        }
        return (users, privateKeys);
    }

    //move block.number forward by a given number of blocks
    function mineBlocks(uint256 numBlocks) external {
        uint256 targetBlock = block.number + numBlocks;
        vm.roll(targetBlock);
    }
}
