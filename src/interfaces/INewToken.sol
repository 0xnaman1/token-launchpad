// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

interface INewToken is IERC20 {
    function mint(address to, uint256 amount) external;

    function burn(uint256 amount) external;
}
