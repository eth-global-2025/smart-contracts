// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Test, console2 } from "forge-std/Test.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { ThesisHubConstants } from "../src/utils/ThesisHubConstants.sol";
import { ThesisHubMaster } from "../src/ThesisHubMaster.sol";
import { ThesisHubConfig } from "../src/ThesisHubConfig.sol";
import { ThesisHubToken } from "../src/Token/ThesisHubToken.sol";
import { ThesisHubTokenFactory } from "../src/factory/ThesisHubTokenFactory.sol";
import { IThesisHubToken } from "../src/interfaces/IThesisHubToken.sol";
import { IThesisHubConfig } from "../src/interfaces/IThesisHubConfig.sol";
import { IThesisHubMaster } from "../src/interfaces/IThesisHubMaster.sol";
import { IThesisHubTokenFactory } from "../src/interfaces/IThesisHubTokenFactory.sol";

contract BaseTest is Test {
    ProxyAdmin public proxyAdmin;
    ThesisHubToken public thesisHubToken;
    ThesisHubMaster public thesisHubMaster;
    ThesisHubConfig public thesisHubConfig;
    ThesisHubTokenFactory public thesisHubTokenFactory;

    address public bot;
    address public user;
    address public admin;

    uint256 public maxTitleLength;
    uint256 public maxDescriptionLength;

    function setUp() public virtual {
        bot = makeAddr("bot");
        user = makeAddr("user");
        admin = makeAddr("admin");

        maxTitleLength = 100;
        maxDescriptionLength = 200;

        vm.startPrank(admin);

        proxyAdmin = new ProxyAdmin(admin);

        ThesisHubConfig thesisHubConfigImpl = new ThesisHubConfig();
        TransparentUpgradeableProxy thesisHubConfigProxy =
            new TransparentUpgradeableProxy(address(thesisHubConfigImpl), address(proxyAdmin), "");
        thesisHubConfig = ThesisHubConfig(address(thesisHubConfigProxy));
        thesisHubConfig.__ThesisHubConfig_Init(admin);

        ThesisHubMaster thesisHubMasterImpl = new ThesisHubMaster();
        TransparentUpgradeableProxy thesisHubMasterProxy =
            new TransparentUpgradeableProxy(address(thesisHubMasterImpl), address(proxyAdmin), "");
        thesisHubMaster = ThesisHubMaster(address(thesisHubMasterProxy));
        thesisHubMaster.__ThesisHubMaster_Init(address(thesisHubConfig), maxTitleLength, maxDescriptionLength);

        ThesisHubTokenFactory thesisHubTokenFactoryImpl = new ThesisHubTokenFactory();
        TransparentUpgradeableProxy thesisHubTokenFactoryProxy =
            new TransparentUpgradeableProxy(address(thesisHubTokenFactoryImpl), address(proxyAdmin), "");
        thesisHubTokenFactory = ThesisHubTokenFactory(address(thesisHubTokenFactoryProxy));
        thesisHubTokenFactory.__ThesisHubTokenFactory_Init(address(thesisHubConfig));

        thesisHubToken = new ThesisHubToken("ThesisHubToken", "ThesisHubToken", IThesisHubToken.TokenInfo({
            author: user,
            cid: "thesiscid",
            title: "test thesis",
            description: "description",
            costInNativeInWei: 1 ether / 100
        }), address(thesisHubConfig));

        thesisHubConfig.setUint256(ThesisHubConstants.PLATFORM_FEE, 500); // 5%
        thesisHubConfig.setAddress(ThesisHubConstants.THESIS_HUB_MASTER_ADDRESS, address(thesisHubMaster));
        thesisHubConfig.setAddress(ThesisHubConstants.TOKEN_FACTORY_ADDRESS, address(thesisHubTokenFactory));

        vm.stopPrank();
    }
}
