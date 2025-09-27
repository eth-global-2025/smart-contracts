// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Create2 } from "@openzeppelin/contracts/utils/Create2.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { UtilLib } from "../utils/UtilLib.sol";
import { ThesisHubToken } from "../Token/ThesisHubToken.sol";
import { IThesisHubConfig } from "../interfaces/IThesisHubConfig.sol";
import { ThesisHubRoleChecker } from "../utils/ThesisHubRoleChecker.sol";
import { IThesisHubTokenFactory } from "../interfaces/IThesisHubTokenFactory.sol";

contract ThesisHubTokenFactory is Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable, IThesisHubTokenFactory {
    IThesisHubConfig public thesisHubConfig;

    constructor() {
        _disableInitializers();
    }

    function __ThesisHubTokenFactory_Init(address _thesisHubConfig) public initializer {
        __Pausable_init();
        __ReentrancyGuard_init();

        thesisHubConfig = IThesisHubConfig(_thesisHubConfig);
    }

    function createToken(
        bytes32 _salt,
        string memory _name,
        string memory _symbol,
        ThesisHubToken.TokenInfo calldata _tokenInfoParams
    )
        external
        nonReentrant
        whenNotPaused
        returns (address tokenAddress)
    {
        ThesisHubRoleChecker.onlyThesisHubMaster(address(thesisHubConfig));

        tokenAddress = Create2.deploy(
            0,
            _salt,
            abi.encodePacked(
                type(ThesisHubToken).creationCode,
                abi.encode(_name, _symbol, _tokenInfoParams, address(thesisHubConfig))
            )
        );

        emit TokenCreated(tokenAddress, _tokenInfoParams.cid);
    }

    function pause() external {
        ThesisHubRoleChecker.onlyAdmin(address(thesisHubConfig));
        _pause();
    }

    function unpause() external {
        ThesisHubRoleChecker.onlyAdmin(address(thesisHubConfig));
        _unpause();
    }

    function updatedThesisHubConfig(address _thesisHubConfig) external {
        ThesisHubRoleChecker.onlyAdmin(address(thesisHubConfig));
        UtilLib.checkNonZeroAddress(_thesisHubConfig);
        thesisHubConfig = IThesisHubConfig(_thesisHubConfig);

        emit ThesisHubConfigUpdated(address(thesisHubConfig));
    }
}
