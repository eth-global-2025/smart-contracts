// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { BaseTest } from "./BaseTest.t.sol";
import { UtilLib } from "../src/utils/UtilLib.sol";
import { IThesisHubMaster } from "../src/interfaces/IThesisHubMaster.sol";
import { IThesisHubConfig } from "../src/interfaces/IThesisHubConfig.sol";
import { ThesisHubToken, IThesisHubToken } from "../src/Token/ThesisHubToken.sol";

contract ThesisHubTokenFactoryTest is BaseTest {
    IThesisHubToken.TokenInfo public assetInfo;

    function setUp() public override {
        super.setUp();

        vm.prank(user);
        address assetAddress = thesisHubMaster.addThesis(
            keccak256(abi.encodePacked("test asset")), 
            IThesisHubToken.TokenInfo({
                title: "test asset",
                cid: "assetcid",
                author: user,
                description: "description",
                costInUSD: 1 ether / 100
            })
        );

        thesisHubToken = ThesisHubToken(assetAddress);

        assetInfo = IThesisHubToken.TokenInfo({
            author: user,
            title: "test asset 1",
            cid: "assetcid",
            description: "description",
            costInUSD: 1 ether / 100
        });
    }

    function test_Initialization() public view {
        assertEq(address(thesisHubTokenFactory.thesisHubConfig()), address(thesisHubConfig));
    }
}

contract CreateTokenTest is ThesisHubTokenFactoryTest {
    error NotThesisHubMaster();
    event TokenCreated(address _tokenAddress, string _tokenCid);

    function test_CreateToken() public {
        vm.prank(address(thesisHubMaster));
        thesisHubTokenFactory.createToken(keccak256(abi.encodePacked("test asset")), "name", "symbol", assetInfo);
    }

    function test_RevertNotThesisHubMaster() public {
        vm.prank(user);
        vm.expectRevert(NotThesisHubMaster.selector);
        thesisHubTokenFactory.createToken(keccak256(abi.encodePacked("test asset")), "name", "symbol", assetInfo);
    }

    function test_EmitTokenCreated() public {
        vm.prank(address(thesisHubMaster));
        vm.expectEmit(false, false, false, false);
        emit TokenCreated(address(thesisHubToken), assetInfo.cid);
        thesisHubTokenFactory.createToken(keccak256(abi.encodePacked("test asset")), "name", "symbol", assetInfo);
    }
}

contract PauseUnpauseTest is ThesisHubTokenFactoryTest {
    function test_PauseUnpause() public {
        vm.startPrank(admin);
        thesisHubTokenFactory.pause();
        assertTrue(thesisHubTokenFactory.paused());

        thesisHubTokenFactory.unpause();
        assertFalse(thesisHubTokenFactory.paused());
        vm.stopPrank();
    }

    function test_RevertNonOwnerPause() public {
        vm.startPrank(user);
        vm.expectRevert();
        thesisHubTokenFactory.pause();
        vm.stopPrank();
    }
}

contract UpdatedThesisHubConfigTest is ThesisHubTokenFactoryTest {
    event ThesisHubConfigUpdated(address _thesisHubConfig);

    function test_RevertNotAdmin() public {
        vm.expectRevert(IThesisHubConfig.NotAdmin.selector);
        thesisHubTokenFactory.updatedThesisHubConfig(address(thesisHubConfig));
    }

    function test_RevertZeroAddressNotAllowed() public {
        vm.prank(admin);
        vm.expectRevert(UtilLib.ZeroAddressNotAllowed.selector);
        thesisHubTokenFactory.updatedThesisHubConfig(address(0));
    }

    function test_EmitThesisHubConfigUpdated() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit ThesisHubConfigUpdated(address(1));
        thesisHubTokenFactory.updatedThesisHubConfig(address(1));
    }
}
