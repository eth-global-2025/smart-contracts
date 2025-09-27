// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { AccessControlUpgradeable } from "@openzeppelin/contracts-upgradeable/access/AccessControlUpgradeable.sol";

import { UtilLib } from "./utils/UtilLib.sol";
import { ThesisHubConstants } from "./utils/ThesisHubConstants.sol";
import { IThesisHubConfig } from "./interfaces/IThesisHubConfig.sol";
import { ThesisHubRoleChecker } from "./utils/ThesisHubRoleChecker.sol";

contract ThesisHubConfig is Initializable, AccessControlUpgradeable, IThesisHubConfig {
    mapping(bytes32 => address) public addressMap;

    mapping(bytes32 => uint256) public uint256Map;

    constructor() {
        _disableInitializers();
    }

    function __ThesisHubConfig_Init(address _admin) public initializer {
        UtilLib.checkNonZeroAddress(_admin);

        __AccessControl_init();
        _grantRole(ThesisHubConstants.DEFAULT_ADMIN_ROLE, _admin);
    }

    function getAddress(bytes32 _key) external view returns (address) {
        return addressMap[_key];
    }

    function getUint256(bytes32 _key) external view returns (uint256) {
        return uint256Map[_key];
    }

    function setAddress(bytes32 _key, address _address) external {
        ThesisHubRoleChecker.onlyAdmin(address(this));

        if (_key == bytes32(0)) {
            revert InvalidKey();
        }
        addressMap[_key] = _address;

        emit AddressSet(_key, _address);
    }

    function setUint256(bytes32 _key, uint256 _value) external {
        ThesisHubRoleChecker.onlyAdmin(address(this));

        if (_key == bytes32(0)) {
            revert InvalidKey();
        }
        uint256Map[_key] = _value;

        emit Uint256Set(_key, _value);
    }
}
