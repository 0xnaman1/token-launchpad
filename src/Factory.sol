// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import {Launch} from "./Launch.sol";
import {OwnableUpgradeable} from "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import {UUPSUpgradeable} from "@openzeppelin/contracts-upgradeable/proxy/utils/UUPSUpgradeable.sol";

contract Factory is OwnableUpgradeable, UUPSUpgradeable {
    address public launchImplementation;
    address public usdcAddress;

    constructor() {
        _disableInitializers();
    }

    function initialize(address _usdcAddress) public initializer {
        __Ownable_init(msg.sender);
        __UUPSUpgradeable_init();
        usdcAddress = _usdcAddress;
        launchImplementation = address(new Launch());
    }

    function createLaunch(
        uint256 _targetAmount,
        string memory _name,
        string memory _symbol
    ) public returns (address) {
        address newLaunch = Clones.clone(launchImplementation);
        Launch(newLaunch).initialize(
            usdcAddress,
            _targetAmount,
            _name,
            _symbol
        );
        return newLaunch;
    }

    function _authorizeUpgrade(address) internal override onlyOwner {}
}
