// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Test, console} from "forge-std/Test.sol";
import {Launch} from "../src/Launch.sol";
import {Factory} from "../src/Factory.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {MockErc20} from "../src/mocks/MockErc20.sol";
import {Utilities} from "./utils/Utilities.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import {NewToken} from "../src/NewToken.sol";

contract LaunchTest is Test {
    address public factory;
    address public proxy;
    Factory public fac;
    Launch public launch;
    MockErc20 public usdc;
    Utilities internal utils;
    address payable[] internal users;
    mapping(address => bytes32) internal privateKeys;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("https://ethereum-sepolia-rpc.publicnode.com"));
        utils = new Utilities();
        (address payable[] memory _users, bytes32[] memory _privateKeys) = utils.createUsers(4);

        users = _users;

        for (uint256 i = 0; i < _users.length; i++) {
            privateKeys[_users[i]] = _privateKeys[i];
        }

        // Created a Mock USDC token
        // Funds would be raised in this token
        usdc = new MockErc20("USD Coin", "USDC", 6);
        usdc.mint(users[0], 1000_000_000 * 10 ** 6);
        usdc.mint(users[1], 1000 * 10 ** 6);
        usdc.mint(users[2], 1000 * 10 ** 6);

        // Create a factory
        Factory f = new Factory();
        factory = address(f);
        bytes memory data = abi.encodeCall(f.initialize, (address(usdc)));
        proxy = address(new ERC1967Proxy(factory, data));
        fac = Factory(proxy);

        // Start a token launch
        vm.startPrank(users[0]);
        launch = Launch(fac.createLaunch(1_000_000 * 1e6, "Bancor Token", "BT")); // Raising 1M USDC

        // usdc.mint(address(launch), 1000 * 10 ** 6);
        usdc.approve(address(launch), 5000 * 10 ** 6);
        launch.setInitialPrice(5000 * 10 ** 6);
        vm.stopPrank();
    }

    function test_Launch() public view {
        assertEq(launch.usdc(), address(usdc));
        assertEq(launch.targetAmount(), 1_000_000 * 1e6);
        assertEq(launch.newToken().name(), "Bancor Token");
        assertEq(launch.newToken().symbol(), "BT");
        assertEq(launch.reserveRatio(), 400);
    }

    function test_BuyAndSell() public {
        NewToken newToken = launch.newToken();

        assertEq(launch.tokensSold(), 0);

        // Buy 100 USDC worth of tokens
        vm.startPrank(users[0]);

        usdc.approve(address(launch), 100 * 10 ** 6);
        uint256 bancorBalance = newToken.balanceOf(users[0]);
        console.log("bancorBalance", bancorBalance);

        assertEq(bancorBalance, 0);
        uint256 tokensToMint = launch.buy(100 * 10 ** 6);
        console.log("tokensToMint", tokensToMint);
        assertEq(launch.tokensSold(), tokensToMint);

        bancorBalance = newToken.balanceOf(users[0]);
        assertEq(bancorBalance, tokensToMint);
        console.log("bancorBalance", bancorBalance);

        vm.stopPrank();

        vm.startPrank(users[1]);
        usdc.approve(address(launch), 100 * 10 ** 6);
        launch.buy(100 * 10 ** 6);
        vm.stopPrank();

        vm.startPrank(users[2]);
        usdc.approve(address(launch), 100 * 10 ** 6);
        launch.buy(100 * 10 ** 6);
        vm.stopPrank();

        uint256 totalTokensSold = launch.tokensSold();
        console.log("totalTokensSold", totalTokensSold);

        // Sell all the tokens
        vm.startPrank(users[0]);
        newToken.approve(address(launch), tokensToMint);
        uint256 usdcReturnAmt = launch.sell(tokensToMint);

        uint256 totalTokensSoldAfterSell = launch.tokensSold();

        assertEq(totalTokensSoldAfterSell, totalTokensSold - tokensToMint);
        assertGe(usdcReturnAmt, 100 * 10 ** 6);

        vm.stopPrank();

        uint256 tokenSold = launch.tokensSold();
        console.log("tokenSold", tokenSold);
    }
}
