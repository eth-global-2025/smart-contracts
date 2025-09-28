// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { console } from "forge-std/console.sol";

import { BaseTest } from "./BaseTest.t.sol";
import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ThesisHubConstants } from "../src/utils/ThesisHubConstants.sol";
import { IThesisHubMaster } from "../src/interfaces/IThesisHubMaster.sol";
import { ThesisHubToken, IThesisHubToken } from "../src/Token/ThesisHubToken.sol";

contract ThesisHubTokenTest is BaseTest {
    event CostUpdated(uint256 _costInUSD);

    function test_Initialization() public view {
        assertEq(thesisHubToken.owner(), user);
        assertEq(thesisHubToken.name(), "ThesisHubToken");
        assertEq(thesisHubToken.symbol(), "ThesisHubToken");
        assertEq(thesisHubToken.cid(), "thesiscid");
        assertEq(thesisHubToken.costInUSD(), 10 ** 6 / 100);
        assertEq(address(thesisHubToken.thesisHubConfig()), address(thesisHubConfig));
    }

    function test_SetCostInUSD() public {
        vm.startPrank(user);
        thesisHubToken.setCostInUSD(2 ether / 100);
        assertEq(thesisHubToken.costInUSD(), 2 ether / 100);
        vm.stopPrank();
    }

    function test_SetCostInUSD_NonAdmin() public {
        vm.startPrank(admin);
        vm.expectRevert(abi.encodeWithSelector(Ownable.OwnableUnauthorizedAccount.selector, admin));
        thesisHubToken.setCostInUSD(2 ether / 100);
        vm.stopPrank();
    }

    function test_SetCostInUSD_Event() public {
        vm.startPrank(user);
        vm.expectEmit(true, true, true, true);
        emit CostUpdated(2 ether / 100);
        thesisHubToken.setCostInUSD(2 ether / 100);
        vm.stopPrank();
    }
}

contract MintTest is BaseTest {
    error NotOwnerOrThesisHubMaster();

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
    }

    function test_Mint_Owner() public {
        vm.startPrank(user);
        thesisHubToken.mint(user, 100);
        assertEq(thesisHubToken.balanceOf(user), 100);
        vm.stopPrank();
    }

    function test_Mint_ThesisHubMaster() public {
        vm.startPrank(address(thesisHubMaster));
        thesisHubToken.mint(bot, 100);
        assertEq(thesisHubToken.balanceOf(bot), 100);
        vm.stopPrank();
    }

    function test_Mint_NonOwnerOrThesisHubMaster() public {
        vm.startPrank(admin);
        vm.expectRevert(IThesisHubToken.NotOwnerOrThesisHubMaster.selector);
        thesisHubToken.mint(admin, 100);
        vm.stopPrank();
    }
}
