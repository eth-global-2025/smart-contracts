// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { console } from "forge-std/console.sol";

import { BaseTest } from "./BaseTest.t.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ThesisHubConstants } from "../src/utils/ThesisHubConstants.sol";
import { IThesisHubMaster } from "../src/interfaces/IThesisHubMaster.sol";
import { ThesisHubToken, IThesisHubToken } from "../src/Token/ThesisHubToken.sol";

contract ThesisHubTokenTest is BaseTest {
    event CostInNativeInWeiUpdated(uint256 _costInNativeInWei);

    function test_Initialization() public view {
        assertEq(thesisHubToken.owner(), user);
        assertEq(thesisHubToken.name(), "ThesisHubToken");
        assertEq(thesisHubToken.symbol(), "ThesisHubToken");
        assertEq(thesisHubToken.cid(), "thesiscid");
        assertEq(thesisHubToken.costInNativeInWei(), 1 ether / 100);
        assertEq(address(thesisHubToken.thesisHubConfig()), address(thesisHubConfig));
    }

    function test_SetCostInNativeInWei() public {
        vm.startPrank(user);
        thesisHubToken.setCostInNativeInWei(2 ether / 100);
        assertEq(thesisHubToken.costInNativeInWei(), 2 ether / 100);
        vm.stopPrank();
    }

    function test_SetCostInNativeInWei_NonAdmin() public {
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, admin));
        thesisHubToken.setCostInNativeInWei(2 ether / 100);
        vm.stopPrank();
    }

    function test_SetCostInNativeInWei_Event() public {
        vm.startPrank(user);
        vm.expectEmit(true, true, true, true);
        emit CostInNativeInWeiUpdated(2 ether / 100);
        thesisHubToken.setCostInNativeInWei(2 ether / 100);
        vm.stopPrank();
    }
}

contract MintTest is BaseTest {
    error NotOwnerOrDxmaster();

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
                costInNativeInWei: 1 ether / 100
            })
        );
        
        thesisHubToken = ThesisHubToken(assetAddress);
    }

    function test_Mint_Owner() public {
        vm.startPrank(user);
        thesisHubToken.mint(user, 100);
        assertEq(thesisHubToken.balanceOf(user), 100);
        vm.stopPrank();
    }

    function test_Mint_Dxmaster() public {
        vm.startPrank(address(thesisHubMaster));
        thesisHubToken.mint(bot, 100);
        assertEq(thesisHubToken.balanceOf(bot), 100);
        vm.stopPrank();
    }

    function test_Mint_NonOwnerOrDxmaster() public {
        vm.startPrank(admin);
        vm.expectRevert(IThesisHubToken.NotOwnerOrThesisHubMaster.selector);
        thesisHubToken.mint(admin, 100);
        vm.stopPrank();
    }
}
