// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.20;

import {ERC20} from "openzeppelin-contracts/contracts/token/ERC20/ERC20.sol";

// import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";

contract MockErc20 is ERC20 {
    uint8 private immutable decimals_;

    constructor(
        string memory name_,
        string memory symbol_,
        uint8 tokenDecimals
    ) ERC20(name_, symbol_) {
        decimals_ = tokenDecimals;
    }

    function mint(address account, uint256 amount) external {
        _mint(account, amount);
    }

    function decimals() public view virtual override returns (uint8) {
        return decimals_;
    }
}
