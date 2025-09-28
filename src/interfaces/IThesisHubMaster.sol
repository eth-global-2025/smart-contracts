// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { IThesisHubToken } from "./IThesisHubToken.sol";

interface IThesisHubMaster {
    // struct CommentInfo {
    //     string comment;
    //     address author;
    // }

    struct UserTokenInfo {
        uint256 amount;
        address tokenAddress;
    }

    error InvalidCid();
    error ThesisAlreadyAdded();
    error EmptyTitle();
    error TitleLengthTooBig();
    error DescriptionTooBig();
    error InvalidTokenAddress();
    error NotThesisHubToken();
    error InvalidAmount();
    error InsufficientAmount();
    error NativeTransferFailed();
    error MoreThanBalance();

    event WithdrawFee(uint256 _amount);
    event ThesisHubConfigUpdated(address _thesisHubConfig);
    // event MaxCommentLengthUpdated(uint256 _maxCommentLength);
    event MaxTitleLengthUpdated(uint256 _maxTitleLength);
    event TokenBought(address _tokenAddress, uint256 _amount, address _buyer);
    // event CommentAdded(address _assetAddress, string _comment, address _author);
    event ThesisAdded(
        string _title, string _cid, address _tokenAddress, address _author, uint256 _costInUSD, string _description
    );
    event MaxDescriptionLengthUpdated(uint256 _maxDescriptionLength);

    function pause() external;
    function unpause() external;
    function updateThesisHubConfig(address _thesisHubConfig) external;
    // function setMaxCommentLength(uint256 _maxCommentLength) external;
    function setMaxTitleLength(uint256 _maxTitleLength) external;
    function setMaxDescriptionLength(uint256 _maxDescriptionLength) external;
    function beforeTokenTransfer(address _from, address _to, uint256 _amount) external;

    function totalTokens() external view returns (uint256);
    function getAllThesisInfos() external view returns (address[] memory allTokenAddresses, IThesisHubToken.TokenInfo[] memory allTokenInfo);
    function getThesisInfo(string memory _tokenCid) external view returns (IThesisHubToken.TokenInfo memory);
    // function getCommentsInfo(address _tokenAddress) external view returns (CommentInfo[] memory);
    function getUserTokenData(address _user) external view returns (UserTokenInfo[] memory);

    function withdrawFee(uint256 _amount) external;
    // function addComment(address _tokenAddress, string calldata _comment) external;
    function addThesis(
        bytes32 _salt,
        IThesisHubToken.TokenInfo calldata _tokenInfo
    )
        external
        returns (address tokenAddress);
}
