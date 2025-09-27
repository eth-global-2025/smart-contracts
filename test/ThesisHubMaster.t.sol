// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { BaseTest } from "./BaseTest.t.sol";

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import { UtilLib } from "../src/utils/UtilLib.sol";
import { IThesisHubConfig } from "../src/interfaces/IThesisHubConfig.sol";
import { ThesisHubConstants } from "../src/utils/ThesisHubConstants.sol";
import { ThesisHubMaster, IThesisHubMaster } from "../src/ThesisHubMaster.sol";
import { ThesisHubToken, IThesisHubToken } from "../src/Token/ThesisHubToken.sol";

// Define events for testing
event TokenBought(address _tokenAddress, uint256 _amount, address _buyer);

contract ThesisHubMasterTest is BaseTest {
    function test_Initialization() public view {
        // assertEq(thesisHubMaster.maxCommentLength(), 100);
        assertEq(thesisHubMaster.maxTitleLength(), 100);
        assertEq(thesisHubMaster.maxDescriptionLength(), 200);

        assertEq(thesisHubMaster.totalTokens(), 0);

        assertTrue(thesisHubConfig.hasRole(ThesisHubConstants.DEFAULT_ADMIN_ROLE, admin));

        assertEq(thesisHubConfig.getUint256(ThesisHubConstants.PLATFORM_FEE), 500);
        assertEq(thesisHubConfig.getAddress(ThesisHubConstants.THESIS_HUB_MASTER_ADDRESS), address(thesisHubMaster));
        assertEq(thesisHubConfig.getAddress(ThesisHubConstants.TOKEN_FACTORY_ADDRESS), address(thesisHubTokenFactory));

        assertEq(address(thesisHubMaster.thesisHubConfig()), address(thesisHubConfig));
    }
}

contract AddThesisTest is BaseTest {
    event ThesisAdded(
        string _title, string _cid, address _tokenAddress, address _author, uint256 _costInNativeInWei, string _description
    );

    function test_RevertEmptyAssetCid() public {
        vm.startPrank(user);
        vm.expectRevert(IThesisHubMaster.InvalidCid.selector);
        thesisHubMaster.addThesis(keccak256(abi.encodePacked("test asset")), IThesisHubToken.TokenInfo({
            title: "test asset",
            cid: "",
            author: user,
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));
        vm.stopPrank();
    }

    function test_RevertEmptyAssetTitle() public {
        vm.startPrank(user);
        vm.expectRevert(IThesisHubMaster.EmptyTitle.selector);
        thesisHubMaster.addThesis(keccak256(abi.encodePacked("test asset")), IThesisHubToken.TokenInfo({
            title: "",
            cid: "asset title",
            author: user,
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));
        vm.stopPrank();
    }

    function test_RevertAssetAlreadyAdded() public {
        vm.startPrank(user);
        thesisHubMaster.addThesis(keccak256(abi.encodePacked("test asset")), IThesisHubToken.TokenInfo({
            title: "asset title",
            cid: "assetcid",
            author: user,
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));
        vm.expectRevert(IThesisHubMaster.ThesisAlreadyAdded.selector);
        thesisHubMaster.addThesis(keccak256(abi.encodePacked("test asset")), IThesisHubToken.TokenInfo({
            title: "asset title",
            cid: "assetcid",
            author: user,
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));
        vm.stopPrank();
    }

    function test_RevertAssetTitleLengthTooBig() public {
        vm.startPrank(user);
        vm.expectRevert(IThesisHubMaster.TitleLengthTooBig.selector);
        thesisHubMaster.addThesis(keccak256(abi.encodePacked("test asset")), IThesisHubToken.TokenInfo({
            title: "abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz",
            cid: "assetcid",
            author: user,
            description: "description",
            costInNativeInWei: 1 ether / 100 // 0.01 ether
        }));
        vm.stopPrank();
    }

    function test_EmitAssetAdded() public {
        vm.prank(user);
        vm.expectEmit(true, true, true, false);
        emit ThesisAdded("asset title", "assetcid", address(0), user, 1 ether / 100, "description");
        address tokenAddress = thesisHubMaster.addThesis(keccak256(abi.encodePacked("test asset 1")), IThesisHubToken.TokenInfo({
            title: "asset title",
            cid: "assetcid",
            author: user,
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));

        IThesisHubToken.TokenInfo memory assetInfo = IThesisHubToken(tokenAddress).getTokenInfo();
        assertEq(assetInfo.author, user);
        assertEq(assetInfo.title, "asset title");
        assertEq(assetInfo.author, user);
        assertEq(assetInfo.cid, "assetcid");
        assertEq(IThesisHubToken(tokenAddress).costInNativeInWei(), 1 ether / 100);

        assertEq(thesisHubMaster.totalTokens(), 1);
    }

    function test_AddLargeAsset() public {
        vm.prank(user);
        address tokenAddress = thesisHubMaster.addThesis(keccak256(abi.encodePacked("test asset 1")), IThesisHubToken.TokenInfo({
            title: "asset title",
            cid: "assetcid",
            author: user,
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));

        IThesisHubToken.TokenInfo memory postInfo = IThesisHubToken(tokenAddress).getTokenInfo();
        assertEq(postInfo.author, user);
        assertEq(postInfo.title, "asset title");
        assertEq(postInfo.cid, "assetcid");
        assertEq(IThesisHubToken(tokenAddress).costInNativeInWei(), 1 ether / 100);
        assertEq(thesisHubMaster.totalTokens(), 1);

        (address[] memory allTokenAddresses, IThesisHubToken.TokenInfo[] memory allPosts) = thesisHubMaster.getAllThesisInfos();
        assertEq(allPosts.length, 1);
        assertEq(allPosts[0].author, user);
        assertEq(allPosts[0].title, "asset title");
        assertEq(allPosts[0].cid, "assetcid");
        assertEq(IThesisHubToken(tokenAddress).costInNativeInWei(), 1 ether / 100);

        assertEq(allTokenAddresses.length, 1);
        assertEq(allTokenAddresses[0], tokenAddress);
    }
}

// contract AddCommentTest is BaseTest {
//     event CommentAdded(address _tokenAddress, string _comment, address _author);
//     address public tokenAddress;

//     function setUp() public override {
//         super.setUp();

//         vm.prank(user);
//         tokenAddress = thesisHubMaster.addThesis(keccak256(abi.encodePacked("test asset 1")), IThesisHubToken.TokenInfo({
//             title: "asset title",
//             assetCid: "assetcid",
//             thumbnailCid: "thumbnailcid",
//             description: "description",
//             costInNativeInWei: 1 ether / 100
//         }));
//     }

//     function test_RevertInvalidAssetAddress() public {
//         vm.expectRevert(IThesisHubMaster.InvalidTokenAddress.selector);
//         thesisHubMaster.addComment(address(0), "Testing...");
//     }

//     function test_RevertEmptyComment() public {
//         vm.expectRevert(IThesisHubMaster.EmptyDescription.selector);
//         thesisHubMaster.addComment(tokenAddress, "");
//     }

//     function test_RevertCommentLengthTooBig() public {
//         vm.expectRevert(IThesisHubMaster.DescriptionTooBig.selector);
//         thesisHubMaster.addComment(
//             tokenAddress,
//             "abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz abcdefghijklmnopqrstuvwxyz"
//         );
//     }

//     function test_EmitAssetComment() public {
//         vm.prank(user);
//         vm.expectEmit(true, true, true, true);
//         emit CommentAdded(tokenAddress, "Testing...", user);
//         thesisHubMaster.addComment(tokenAddress, "Testing...");

//         IThesisHubMaster.CommentInfo[] memory comments = thesisHubMaster.getCommentsInfo(tokenAddress);
//         assertEq(comments.length, 1);
//         assertEq(comments[0].author, user);
//         assertEq(comments[0].comment, "Testing...");
//     }
// }

contract BuyAssetTest is BaseTest {
    error NativeTransferFailed();

    event AssetBought(address _tokenAddress, uint256 _amount, address _buyer);

    address public author;
    address public tokenAddress;

    function setUp() public override {
        super.setUp();

        author = makeAddr("author");
        vm.prank(author);
        tokenAddress = thesisHubMaster.addThesis(keccak256(abi.encodePacked("test asset 1")), IThesisHubToken.TokenInfo({
            title: "asset title",
            cid: "assetcid",
            author: author,
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));

        thesisHubToken = ThesisHubToken(tokenAddress);
    }

    function test_RevertInvalidAssetCid() public {
        vm.expectRevert(IThesisHubMaster.InvalidTokenAddress.selector);
        thesisHubMaster.buyToken(address(0), 1);
    }

    function test_RevertInvalidAmount() public {
        vm.expectRevert(IThesisHubMaster.InvalidAmount.selector);
        thesisHubMaster.buyToken(tokenAddress, 0);
    }

    function test_RevertInsufficientAmount() public {
        vm.expectRevert(IThesisHubMaster.InsufficientAmount.selector);
        thesisHubMaster.buyToken(tokenAddress, 1);
    }

    function test_RevertRefundableNativeTransferFailed() public {
        deal(address(thesisHubConfig), 1 ether); // Any non-payable address

        vm.prank(address(thesisHubConfig));
        vm.expectRevert(NativeTransferFailed.selector);
        thesisHubMaster.buyToken{ value: 1 ether }(tokenAddress, 1);
    }

    function test_RevertAuthorNativeTransferFailed() public {
        vm.prank(address(thesisHubConfig));
        tokenAddress = thesisHubMaster.addThesis(keccak256(abi.encodePacked("test asset 1")), IThesisHubToken.TokenInfo({
            title: "asset title",
            cid: "assetcid1",
            author: author,
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));

        deal(user, 1 ether);
        vm.prank(user);
        vm.expectRevert(NativeTransferFailed.selector);
        thesisHubMaster.buyToken{ value: 1 ether }(tokenAddress, 1);
    }

    function test_EmitAssetBought() public {
        deal(user, 1 ether / 100);
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit TokenBought(tokenAddress, 1, user);
        thesisHubMaster.buyToken{ value: 1 ether / 100 }(tokenAddress, 1);

        assertEq(thesisHubToken.balanceOf(user), 1);
        assertEq(address(user).balance, 0);
        assertEq(address(author).balance, 95 * 1 ether / 100 / 100);
        assertEq(address(thesisHubMaster).balance, 5 * 1 ether / 100 / 100);

        IThesisHubMaster.UserTokenInfo[] memory userAssetData = thesisHubMaster.getUserTokenData(user);
        assertEq(userAssetData.length, 1);
        assertEq(userAssetData[0].tokenAddress, tokenAddress);
        assertEq(userAssetData[0].amount, 1);
    }

    function test_BuyAssetWithMoreThanRequiredAmount() public {
        deal(user, 1 ether);
        vm.prank(user);
        vm.expectEmit(true, true, true, true);
        emit TokenBought(tokenAddress, 3, user);
        thesisHubMaster.buyToken{ value: 1 ether }(tokenAddress, 3);

        assertEq(thesisHubToken.balanceOf(user), 3);
        assertEq(address(user).balance, 97 ether / 100);
        assertEq(address(author).balance, 95 * 3 ether / 100 / 100);
        assertEq(address(thesisHubMaster).balance, 5 * 3 ether / 100 / 100);

        IThesisHubMaster.UserTokenInfo[] memory userAssetData = thesisHubMaster.getUserTokenData(user);
        assertEq(userAssetData.length, 1);
        assertEq(userAssetData[0].tokenAddress, tokenAddress);
        assertEq(userAssetData[0].amount, 3);
    }
}

contract BeforeTokenTransferTest is BaseTest {
    error NotdXAsset();

    address public author;
    address public tokenAddress;

    function setUp() public override {
        super.setUp();

        author = makeAddr("author");
        vm.prank(author);
        tokenAddress = thesisHubMaster.addThesis(keccak256(abi.encodePacked("test asset 1")), IThesisHubToken.TokenInfo({
            title: "asset title",
            cid: "assetcid",
            author: author,
            description: "description",
            costInNativeInWei: 1 ether / 100
        }));

        thesisHubToken = ThesisHubToken(tokenAddress);
    }

    function test_RevertNotDxAsset() public {
        vm.prank(user);
        vm.expectRevert();
        thesisHubMaster.beforeTokenTransfer(user, author, 1);
    }

    function test_AssetMint() public {
        deal(user, 1 ether / 100);
        vm.prank(user);
        thesisHubMaster.buyToken{ value: 1 ether / 100 }(tokenAddress, 1);

        assertEq(thesisHubToken.balanceOf(user), 1);
        assertEq(address(user).balance, 0);
        assertEq(address(author).balance, 95 * 1 ether / 100 / 100);
        assertEq(address(thesisHubMaster).balance, 5 * 1 ether / 100 / 100);

        IThesisHubMaster.UserTokenInfo[] memory userAssetData = thesisHubMaster.getUserTokenData(user);
        assertEq(userAssetData.length, 1);
        assertEq(userAssetData[0].tokenAddress, tokenAddress);
        assertEq(userAssetData[0].amount, 1);
    }

    function test_AssetBurn() public {
        deal(user, 1 ether / 100);
        vm.prank(user);
        thesisHubMaster.buyToken{ value: 1 ether / 100 }(tokenAddress, 1);

        assertEq(thesisHubToken.balanceOf(user), 1);
        assertEq(address(user).balance, 0);
        assertEq(address(author).balance, 95 * 1 ether / 100 / 100);
        assertEq(address(thesisHubMaster).balance, 5 * 1 ether / 100 / 100);

        vm.prank(user);
        thesisHubToken.burn(1);

        assertEq(thesisHubToken.balanceOf(user), 0);
        assertEq(address(user).balance, 0);
        assertEq(address(author).balance, 95 * 1 ether / 100 / 100);
        assertEq(address(thesisHubMaster).balance, 5 * 1 ether / 100 / 100);

        IThesisHubMaster.UserTokenInfo[] memory userAssetData = thesisHubMaster.getUserTokenData(user);
        assertEq(userAssetData.length, 0);
    }

    function test_AssetTransfer() public {
        address user2 = makeAddr("user2");

        deal(user, 1 ether / 100);
        vm.prank(user);
        thesisHubMaster.buyToken{ value: 1 ether / 100 }(tokenAddress, 1);

        assertEq(thesisHubToken.balanceOf(user), 1);
        assertEq(address(user).balance, 0);
        assertEq(address(author).balance, 95 * 1 ether / 100 / 100);
        assertEq(address(thesisHubMaster).balance, 5 * 1 ether / 100 / 100);

        vm.prank(user);
        thesisHubToken.transfer(user2, 1);

        assertEq(thesisHubToken.balanceOf(user), 0);
        assertEq(thesisHubToken.balanceOf(user2), 1);
        assertEq(address(user).balance, 0);
        assertEq(address(user2).balance, 0);
        assertEq(address(author).balance, 95 * 1 ether / 100 / 100);
        assertEq(address(thesisHubMaster).balance, 5 * 1 ether / 100 / 100);

        IThesisHubMaster.UserTokenInfo[] memory userAssetData = thesisHubMaster.getUserTokenData(user);
        assertEq(userAssetData.length, 0);
        IThesisHubMaster.UserTokenInfo[] memory user2AssetData = thesisHubMaster.getUserTokenData(user2);
        assertEq(user2AssetData.length, 1);
        assertEq(user2AssetData[0].tokenAddress, tokenAddress);
        assertEq(user2AssetData[0].amount, 1);
    }

    function test_AssetTransferAgain() public {
        address user2 = makeAddr("user2");

        deal(user, 2 ether / 100);
        vm.prank(user);
        thesisHubMaster.buyToken{ value: 2 ether / 100 }(tokenAddress, 2);

        assertEq(thesisHubToken.balanceOf(user), 2);
        assertEq(address(user).balance, 0);
        assertEq(address(author).balance, 95 * 2 ether / 100 / 100);
        assertEq(address(thesisHubMaster).balance, 5 * 2 ether / 100 / 100);

        vm.prank(user);
        thesisHubToken.transfer(user2, 1);

        assertEq(thesisHubToken.balanceOf(user), 1);
        assertEq(thesisHubToken.balanceOf(user2), 1);
        assertEq(address(user).balance, 0);
        assertEq(address(user2).balance, 0);
        assertEq(address(author).balance, 95 * 2 ether / 100 / 100);
        assertEq(address(thesisHubMaster).balance, 5 * 2 ether / 100 / 100);

        IThesisHubMaster.UserTokenInfo[] memory userAssetData = thesisHubMaster.getUserTokenData(user);
        assertEq(userAssetData.length, 1);
        assertEq(userAssetData[0].tokenAddress, tokenAddress);
        assertEq(userAssetData[0].amount, 1);
        IThesisHubMaster.UserTokenInfo[] memory user2AssetData = thesisHubMaster.getUserTokenData(user2);
        assertEq(user2AssetData.length, 1);
        assertEq(user2AssetData[0].tokenAddress, tokenAddress);
        assertEq(user2AssetData[0].amount, 1);

        vm.prank(user);
        thesisHubToken.transfer(user2, 1);

        assertEq(thesisHubToken.balanceOf(user), 0);
        assertEq(thesisHubToken.balanceOf(user2), 2);
        assertEq(address(user).balance, 0);
        assertEq(address(user2).balance, 0);
        assertEq(address(author).balance, 95 * 2 ether / 100 / 100);
        assertEq(address(thesisHubMaster).balance, 5 * 2 ether / 100 / 100);

        userAssetData = thesisHubMaster.getUserTokenData(user);
        assertEq(userAssetData.length, 0);
        user2AssetData = thesisHubMaster.getUserTokenData(user2);
        assertEq(user2AssetData.length, 1);
        assertEq(user2AssetData[0].tokenAddress, address(thesisHubToken));
        assertEq(user2AssetData[0].amount, 2);
    }
}

contract PauseUnpauseTest is BaseTest {
    function test_PauseUnpause() public {
        vm.startPrank(admin);
        thesisHubMaster.pause();
        assertTrue(thesisHubMaster.paused());

        thesisHubMaster.unpause();
        assertFalse(thesisHubMaster.paused());
        vm.stopPrank();
    }

    function test_RevertNonOwnerPause() public {
        vm.startPrank(user);
        vm.expectRevert();
        thesisHubMaster.pause();
        vm.stopPrank();
    }
}

// contract setMaxCommentLengthTest is BaseTest {
//     event MaxCommentLengthUpdated(uint256 _maxCommentLength);

//     function test_RevertNotAdmin() public {
//         vm.expectRevert(IThesisHubConfig.NotAdmin.selector);
//         thesisHubMaster.setMaxCommentLength(2 days);
//     }

//     function test_EmitCommentLengthUpdated() public {
//         vm.prank(admin);
//         vm.expectEmit(true, true, true, true);
//         emit MaxCommentLengthUpdated(2 days);
//         thesisHubMaster.setMaxCommentLength(2 days);

//         assertEq(thesisHubMaster.maxCommentLength(), 2 days);
//     }
// }

contract setMaxTitleLengthTest is BaseTest {
    event MaxTitleLengthUpdated(uint256 _maxTitleLength);

    function test_RevertNotAdmin() public {
        vm.expectRevert(IThesisHubConfig.NotAdmin.selector);
        thesisHubMaster.setMaxTitleLength(200);
    }

    function test_EmitMaxPostTitleLengthUpdated() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit MaxTitleLengthUpdated(200);
        thesisHubMaster.setMaxTitleLength(200);

        assertEq(thesisHubMaster.maxTitleLength(), 200);
    }
}

contract updateThesisHubConfigTest is BaseTest {
    event ThesisHubConfigUpdated(address _thesisHubConfig);

    function test_RevertNotAdmin() public {
        vm.expectRevert(IThesisHubConfig.NotAdmin.selector);
        thesisHubMaster.updateThesisHubConfig(address(thesisHubConfig));
    }

    function test_RevertZeroAddressNotAllowed() public {
        vm.prank(admin);
        vm.expectRevert(UtilLib.ZeroAddressNotAllowed.selector);
        thesisHubMaster.updateThesisHubConfig(address(0));
    }

    function test_EmitThesisHubConfigUpdated() public {
        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit ThesisHubConfigUpdated(address(1));
        thesisHubMaster.updateThesisHubConfig(address(1));
    }
}

contract withdrawFeeTest is BaseTest {
    error MoreThanBalance();
    error NativeTransferFailed();

    event WithdrawFee(uint256 _amount);

    function test_RevertNotAdmin() public {
        vm.expectRevert(IThesisHubConfig.NotAdmin.selector);
        thesisHubMaster.withdrawFee(1 ether);
    }

    function test_RevertMoreThanBalance() public {
        vm.prank(admin);
        vm.expectRevert(MoreThanBalance.selector);
        thesisHubMaster.withdrawFee(1 ether);
    }

    function test_WithdrawFee() public {
        deal(address(thesisHubMaster), 1 ether);
        vm.prank(admin);
        thesisHubMaster.withdrawFee(1 ether);

        assertEq(address(admin).balance, 1 ether);
        assertEq(address(thesisHubMaster).balance, 0);
    }

    function test_EmitWithdrawFee() public {
        deal(address(thesisHubMaster), 1 ether);

        vm.prank(admin);
        vm.expectEmit(true, true, true, true);
        emit WithdrawFee(1 ether);
        thesisHubMaster.withdrawFee(1 ether);
    }

    function test_RevertNativeTransferFailed() public {
        vm.prank(admin);
        thesisHubConfig.grantRole(ThesisHubConstants.DEFAULT_ADMIN_ROLE, address(thesisHubConfig));

        deal(address(thesisHubMaster), 1 ether);

        vm.prank(address(thesisHubConfig));
        vm.expectRevert(NativeTransferFailed.selector);
        thesisHubMaster.withdrawFee(1 ether);
    }
}
