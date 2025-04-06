// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Script, console} from "forge-std/Script.sol";

import "../src/mocks/MockErc20.sol";
import {Launch} from "../src/Launch.sol";
import {Factory} from "../src/Factory.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";

contract DeployFactory is Script {
    uint256 deployer = vm.envUint("PK");
    address deployerAddress = vm.addr(deployer);

    function run() public {
        vm.createSelectFork("sepolia");
        vm.startBroadcast(deployer);

        // Deploy USDC
        MockErc20 usdc = new MockErc20("USD Coin", "USDC", 6);

        console.log("USDC deployed at", address(usdc));

        // Mint USDC to deployer
        usdc.mint(deployerAddress, 1000_000_000 * 1e6);

        // Deploy Factory
        Factory f = new Factory();
        address factory = address(f);
        bytes memory data = abi.encodeCall(f.initialize, (address(usdc)));
        address proxy = address(new ERC1967Proxy(factory, data));
        Factory fac = Factory(proxy);
        console.log("Factory deployed at", address(fac));

        // Deploy Launch
        Launch launch = Launch(
            fac.createLaunch(1_000_000 * 1e6, "Bancor Token", "BT")
        );

        console.log("Launch deployed at", address(launch));

        usdc.approve(address(launch), 5000 * 10 ** 6);
        launch.setInitialPrice(5000 * 10 ** 6);

        vm.stopBroadcast();
    }
}
