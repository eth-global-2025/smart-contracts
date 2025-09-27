// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { ProxyAdmin } from "@openzeppelin/contracts/proxy/transparent/ProxyAdmin.sol";
import { TransparentUpgradeableProxy } from "@openzeppelin/contracts/proxy/transparent/TransparentUpgradeableProxy.sol";

import { Test, console2 } from "forge-std/Test.sol";
import { ThesisHubConfig, IThesisHubConfig } from "../src/ThesisHubConfig.sol";
import { ThesisHubConstants } from "../src/utils/ThesisHubConstants.sol";

// Define the event that matches the contract
event AddressSet(bytes32 indexed key, address address_);

event Uint256Set(bytes32 indexed key, uint256 value);

contract ThesisHubConfigTest is Test {
    ProxyAdmin public proxyAdmin;
    ThesisHubConfig public thesisHubConfig;

    address public admin = makeAddr("admin");

    function setUp() external {
        vm.startPrank(admin);

        proxyAdmin = new ProxyAdmin(admin);

        ThesisHubConfig thesisHubConfigImpl = new ThesisHubConfig();
        TransparentUpgradeableProxy thesisHubConfigProxy =
            new TransparentUpgradeableProxy(address(thesisHubConfigImpl), address(proxyAdmin), "");
        thesisHubConfig = ThesisHubConfig(address(thesisHubConfigProxy));
        thesisHubConfig.__ThesisHubConfig_Init(admin);

        vm.stopPrank();
    }
}

contract GetSetAddressTest is ThesisHubConfigTest {
    bytes32 public constant TEST_KEY = keccak256("TEST_KEY");
    address public testAddress = makeAddr("testAddress");
    address public nonAdmin = makeAddr("nonAdmin");

    function test_Initialization() public view {
        assertTrue(thesisHubConfig.hasRole(thesisHubConfig.DEFAULT_ADMIN_ROLE(), admin));
        assertEq(thesisHubConfig.getAddress(TEST_KEY), address(0));
    }

    function test_SetAddress() public {
        vm.startPrank(admin);
        thesisHubConfig.setAddress(TEST_KEY, testAddress);
        assertEq(thesisHubConfig.getAddress(TEST_KEY), testAddress);
        vm.stopPrank();
    }

    function test_SetAddress_NonAdmin() public {
        vm.startPrank(nonAdmin);
        vm.expectRevert(IThesisHubConfig.NotAdmin.selector);
        thesisHubConfig.setAddress(TEST_KEY, testAddress);
        vm.stopPrank();
    }

    function test_SetAddress_InvalidKey() public {
        vm.startPrank(admin);
        vm.expectRevert(IThesisHubConfig.InvalidKey.selector);
        thesisHubConfig.setAddress(bytes32(0), testAddress);
        vm.stopPrank();
    }

    function test_SetAddress_Event() public {
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit AddressSet(TEST_KEY, testAddress);
        thesisHubConfig.setAddress(TEST_KEY, testAddress);
        vm.stopPrank();
    }
}

contract GetSetUint256Test is ThesisHubConfigTest {
    bytes32 public constant TEST_KEY = keccak256("TEST_KEY");
    address public nonAdmin = makeAddr("nonAdmin");
    uint256 public testUint256 = 100;

    function test_Initialization() public view {
        assertEq(thesisHubConfig.getUint256(TEST_KEY), 0);
    }

    function test_SetUint256() public {
        vm.startPrank(admin);
        thesisHubConfig.setUint256(TEST_KEY, testUint256);
        assertEq(thesisHubConfig.getUint256(TEST_KEY), testUint256);
        vm.stopPrank();
    }

    function test_SetUint256_NonAdmin() public {
        vm.startPrank(nonAdmin);
        vm.expectRevert(IThesisHubConfig.NotAdmin.selector);
        thesisHubConfig.setUint256(TEST_KEY, testUint256);
        vm.stopPrank();
    }

    function test_SetUint256_InvalidKey() public {
        vm.startPrank(admin);
        vm.expectRevert(IThesisHubConfig.InvalidKey.selector);
        thesisHubConfig.setUint256(bytes32(0), testUint256);
        vm.stopPrank();
    }

    function test_SetUint256_Event() public {
        vm.startPrank(admin);
        vm.expectEmit(true, true, true, true);
        emit Uint256Set(TEST_KEY, testUint256);
        thesisHubConfig.setUint256(TEST_KEY, testUint256);
        vm.stopPrank();
    }
}
