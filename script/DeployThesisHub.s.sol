// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Script, console2 } from "forge-std/Script.sol";

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { ThesisHubConstants } from "../src/utils/ThesisHubConstants.sol";
import { ThesisHubMaster, IThesisHubMaster } from "../src/ThesisHubMaster.sol";
import { ThesisHubConfig, IThesisHubConfig } from "../src/ThesisHubConfig.sol";
import { ThesisHubTokenFactory } from "../src/factory/ThesisHubTokenFactory.sol";

contract DeployThesisHub is Script {
    ProxyAdmin public proxyAdmin;
    ThesisHubMaster public thesisHubMaster;
    ThesisHubConfig public thesisHubConfig;
    ThesisHubTokenFactory public thesisHubTokenFactory;
    address public pyUSD;

    address admin;
    uint256 maxTitleLength;
    uint256 maxDescriptionLength;

    function setUp() external {
        admin = 0xEBA436aE4012D8194a5b44718a8ba6ec553241bE;
        maxTitleLength = 100;
        maxDescriptionLength = 200;
    }

    function run() public {
        vm.startBroadcast();

        proxyAdmin = new ProxyAdmin(admin);

        pyUSD = 0xCaC524BcA292aaade2DF8A05cC58F0a65B1B3bB9;

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

        thesisHubConfig.setUint256(ThesisHubConstants.PLATFORM_FEE, 500); // 5%
        thesisHubConfig.setAddress(ThesisHubConstants.PYUSD_ADDRESS, address(pyUSD));
        thesisHubConfig.setAddress(ThesisHubConstants.THESIS_HUB_MASTER_ADDRESS, address(thesisHubMaster));
        thesisHubConfig.setAddress(ThesisHubConstants.TOKEN_FACTORY_ADDRESS, address(thesisHubTokenFactory));

        console2.log("proxyAdmin deployed at: ", address(proxyAdmin));
        console2.log("thesisHubConfig deployed at: ", address(thesisHubConfig));
        console2.log("thesisHubMaster deployed at: ", address(thesisHubMaster));
        console2.log("thesisHubTokenFactory deployed at: ", address(thesisHubTokenFactory));

        // dXmaster.addAsset(bytes32(0), "test asset 0", "bafybeib3byag2t25vbzxjsrcc2r3amhedyxtsgynpz7gpbmdi6r3qmg53q", 0);
        // dXmaster.addAsset(bytes32(0), "test asset 1", "bafkreibex6hyc624d2gxz63i2omrrxbqbh7bmgzi6bwc6m4ib3or3eq7lq", 1 ether / 100);

        // dXmaster.buyAsset("bafybeib3byag2t25vbzxjsrcc2r3amhedyxtsgynpz7gpbmdi6r3qmg53q", 1);
        // dXmaster.buyAsset{value: 1 ether / 80}("bafkreibex6hyc624d2gxz63i2omrrxbqbh7bmgzi6bwc6m4ib3or3eq7lq", 1);

        vm.stopBroadcast();
    }
}
