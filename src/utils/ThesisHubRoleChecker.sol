// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { IAccessControl } from "@openzeppelin/contracts/access/IAccessControl.sol";

import { ThesisHubConstants } from "./ThesisHubConstants.sol";
import { IThesisHubConfig } from "../interfaces/IThesisHubConfig.sol";

library ThesisHubRoleChecker {
    function onlyRole(address _thesisHubConfig, bytes32 _role) external view {
        if (!IAccessControl(_thesisHubConfig).hasRole(_role, msg.sender)) {
            revert IThesisHubConfig.CallerUnauthorized();
        }
    }

    function onlyAdmin(address _thesisHubConfig) external view {
        if (!IAccessControl(_thesisHubConfig).hasRole(ThesisHubConstants.DEFAULT_ADMIN_ROLE, msg.sender)) {
            revert IThesisHubConfig.NotAdmin();
        }
    }

    function onlyThesisHubMaster(address _thesisHubConfig) external view {
        if (IThesisHubConfig(_thesisHubConfig).getAddress(ThesisHubConstants.THESIS_HUB_MASTER_ADDRESS) != msg.sender) {
            revert IThesisHubConfig.NotThesisHubMaster();
        }
    }
}
