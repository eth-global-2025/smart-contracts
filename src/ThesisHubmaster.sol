// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import { Strings } from "@openzeppelin/contracts/utils/Strings.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import { Initializable } from "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";
import { PausableUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/PausableUpgradeable.sol";
import { ReentrancyGuardUpgradeable } from "@openzeppelin/contracts-upgradeable/utils/ReentrancyGuardUpgradeable.sol";

import { UtilLib } from "./utils/UtilLib.sol";
import { IThesisHubToken } from "./interfaces/IThesisHubToken.sol";
import { ThesisHubConstants } from "./utils/ThesisHubConstants.sol";
import { IThesisHubConfig } from "./interfaces/IThesisHubConfig.sol";
import { IThesisHubMaster } from "./interfaces/IThesisHubMaster.sol";
import { ThesisHubRoleChecker } from "./utils/ThesisHubRoleChecker.sol";
import { IThesisHubTokenFactory } from "./interfaces/IThesisHubTokenFactory.sol";

contract ThesisHubMaster is Initializable, PausableUpgradeable, ReentrancyGuardUpgradeable, IThesisHubMaster {
    using SafeERC20 for IERC20;

    address[] public tokenAddresses;
    mapping(string => address) public tokenData;
    // mapping(address => CommentInfo[]) public commentData;
    mapping(address => UserTokenInfo[]) public userTokenData;

    IThesisHubConfig public thesisHubConfig;
    uint256 public maxTitleLength;
    // uint256 public maxCommentLength;
    uint256 public maxDescriptionLength;

    constructor() {
        _disableInitializers();
    }

    function __ThesisHubMaster_Init(
        address _thesisHubConfig,
        // uint256 _maxCommentLength,
        uint256 _maxTitleLength,
        uint256 _maxDescriptionLength
    )
        public
        initializer
    {
        __Pausable_init();
        __ReentrancyGuard_init();

        thesisHubConfig = IThesisHubConfig(_thesisHubConfig);
        maxTitleLength = _maxTitleLength;
        // maxCommentLength = _maxCommentLength;
        maxDescriptionLength = _maxDescriptionLength;
    }

    modifier isValidThesis(IThesisHubToken.TokenInfo calldata _tokenInfo) {
        if (bytes(_tokenInfo.cid).length == 0) {
            revert InvalidCid();
        }
        if (tokenData[_tokenInfo.cid] != address(0)) {
            revert ThesisAlreadyAdded();
        }
        if (bytes(_tokenInfo.title).length == 0) {
            revert EmptyTitle();
        }
        if (bytes(_tokenInfo.title).length > maxTitleLength) {
            revert TitleLengthTooBig();
        }
        if (bytes(_tokenInfo.description).length > maxDescriptionLength) {
            revert DescriptionTooBig();
        }
        _;
    }

    // modifier isValidComment(address _tokenAddress, string calldata _comment) {
    //     if (bytes(_comment).length == 0) {
    //         revert EmptyComment();
    //     }
    //     if (bytes(_comment).length > maxTitleLength) {
    //         revert CommentLengthTooBig();
    //     }
    //     _;
    // }

    modifier onlyThesisHubToken(address _tokenAddress) {
        if (_tokenAddress == address(0)) {
            revert InvalidTokenAddress();
        }
        string memory tokenCid = IThesisHubToken(_tokenAddress).cid();
        if (tokenData[tokenCid] != _tokenAddress) {
            revert NotThesisHubToken();
        }
        _;
    }

    modifier isValidBuy(address _tokenAddress, uint256 _amount) {
        if (_amount == 0) {
            revert InvalidAmount();
        }
        if (IThesisHubToken(_tokenAddress).costInNativeInWei() * _amount > msg.value) {
            revert InsufficientAmount();
        }
        _;
    }

    function totalTokens() external view returns (uint256) {
        return tokenAddresses.length;
    }

    function getThesisInfo(string memory _tokenCid) public view returns (IThesisHubToken.TokenInfo memory) {
        return IThesisHubToken(tokenData[_tokenCid]).getTokenInfo();
    }

    function getAllThesisInfos() external view returns (address[] memory allTokenAddresses, IThesisHubToken.TokenInfo[] memory allTokenInfo) {
        allTokenInfo = new IThesisHubToken.TokenInfo[](tokenAddresses.length);
        for (uint256 i = 0; i < tokenAddresses.length; i++) {
            allTokenInfo[i] = IThesisHubToken(tokenAddresses[i]).getTokenInfo();
        }
        allTokenAddresses = tokenAddresses;
    }

    // function getCommentsInfo(address _assetAddress) external view returns (CommentInfo[] memory) {
    //     return commentData[_assetAddress];
    // }

    function getUserTokenData(address _user) external view returns (UserTokenInfo[] memory) {
        return userTokenData[_user];
    }

    function addThesis(
        bytes32 _salt,
        IThesisHubToken.TokenInfo calldata _tokenInfo
    )
        external
        nonReentrant
        whenNotPaused
        isValidThesis(_tokenInfo)
        returns (address tokenAddress)
    {

        string memory name = string.concat("ThesisHubToken", Strings.toString(tokenAddresses.length));
        string memory symbol = string.concat("ThesisHubToken", Strings.toString(tokenAddresses.length));

        address tokenFactoryAddress = thesisHubConfig.getAddress(ThesisHubConstants.TOKEN_FACTORY_ADDRESS);
        tokenAddress =
            IThesisHubTokenFactory(tokenFactoryAddress).createToken(_salt, name, symbol, IThesisHubToken.TokenInfo({
                author: msg.sender,
                cid: _tokenInfo.cid,
                title: _tokenInfo.title,
                description: _tokenInfo.description,
                costInNativeInWei: _tokenInfo.costInNativeInWei
            }));

        tokenAddresses.push(tokenAddress);
        tokenData[_tokenInfo.cid] = tokenAddress;

        emit ThesisAdded(_tokenInfo.title, _tokenInfo.cid, tokenAddress, msg.sender, _tokenInfo.costInNativeInWei, _tokenInfo.description);
    }

    // function addComment(
    //     address _tokenAddress,
    //     string calldata _comment
    // )
    //     external
    //     nonReentrant
    //     whenNotPaused
    //     onlyThesisHubToken(_tokenAddress)
    //     isValidComment(_tokenAddress, _comment)
    // {
    //     commentData[_tokenAddress].push(CommentInfo({ comment: _comment, author: msg.sender }));

    //     emit CommentAdded(_tokenAddress, _comment, msg.sender);
    // }

    function buyToken(
        address _tokenAddress,
        uint256 _amount
    )
        external
        payable
        nonReentrant
        whenNotPaused
        onlyThesisHubToken(_tokenAddress)
        isValidBuy(_tokenAddress, _amount)
    {
        IThesisHubToken.TokenInfo memory tokenInfo = IThesisHubToken(_tokenAddress).getTokenInfo();

        _handleTransfer(_amount, msg.value, tokenInfo.costInNativeInWei, tokenInfo.author);

        IThesisHubToken(_tokenAddress).mint(msg.sender, _amount);

        emit TokenBought(_tokenAddress, _amount, msg.sender);
    }

    function pause() external {
        ThesisHubRoleChecker.onlyAdmin(address(thesisHubConfig));
        _pause();
    }

    function unpause() external {
        ThesisHubRoleChecker.onlyAdmin(address(thesisHubConfig));
        _unpause();
    }

    function setMaxTitleLength(uint256 _maxTitleLength) external {
        ThesisHubRoleChecker.onlyAdmin(address(thesisHubConfig));
        maxTitleLength = _maxTitleLength;

        emit MaxTitleLengthUpdated(maxTitleLength);
    }

    // function setMaxCommentLength(uint256 _maxCommentLength) external {
    //     ThesisHubRoleChecker.onlyAdmin(address(dXConfig));
    //     maxCommentLength = _maxCommentLength;

    //     emit MaxCommentLengthUpdated(maxCommentLength);
    // }

    function setMaxDescriptionLength(uint256 _maxDescriptionLength) external {
        ThesisHubRoleChecker.onlyAdmin(address(thesisHubConfig));
        maxDescriptionLength = _maxDescriptionLength;

        emit MaxDescriptionLengthUpdated(maxDescriptionLength);
    }

    function updateThesisHubConfig(address _thesisHubConfig) external {
        ThesisHubRoleChecker.onlyAdmin(address(thesisHubConfig));
        UtilLib.checkNonZeroAddress(_thesisHubConfig);
        thesisHubConfig = IThesisHubConfig(_thesisHubConfig);

        emit ThesisHubConfigUpdated(address(thesisHubConfig));
    }

    function withdrawFee(uint256 _amount) external {
        ThesisHubRoleChecker.onlyAdmin(address(thesisHubConfig));

        if (_amount > address(this).balance) {
            revert MoreThanBalance();
        }

        (bool success,) = payable(msg.sender).call{ value: _amount }("");
        if (!success) revert NativeTransferFailed();

        emit WithdrawFee(_amount);
    }

    function beforeTokenTransfer(address _from, address _to, uint256 _amount) external onlyThesisHubToken(msg.sender) {
        if (_from != address(0)) {
            UserTokenInfo[] storage _userTokenData = userTokenData[_from];
            for (uint256 i = 0; i < _userTokenData.length; i++) {
                if (_userTokenData[i].tokenAddress == msg.sender) {
                    _userTokenData[i].amount -= _amount;
                    if (_userTokenData[i].amount == 0) {
                        _userTokenData[i] = _userTokenData[_userTokenData.length - 1];
                        _userTokenData.pop();
                    }
                    break;
                }
            }
        }

        if (_to != address(0)) {
            bool isFound = false;
            UserTokenInfo[] storage _userTokenData = userTokenData[_to];
            for (uint256 i = 0; i < _userTokenData.length; i++) {
                if (_userTokenData[i].tokenAddress == msg.sender) {
                    _userTokenData[i].amount += _amount;
                    isFound = true;
                    break;
                }
            }
            if (!isFound) {
                _userTokenData.push(UserTokenInfo({ tokenAddress: msg.sender, amount: _amount }));
            }
        }
    }

    function _handleTransfer(
        uint256 _amount,
        uint256 _msgValue,
        uint256 _costInNativeInWei,
        address _author
    )
        internal
    {
        uint256 totalAmount = _costInNativeInWei * _amount;

        uint256 refundableAmount = _msgValue - totalAmount;
        if (refundableAmount > 0) {
            (bool refundableSuccess,) = payable(msg.sender).call{ value: refundableAmount }("");
            if (!refundableSuccess) revert NativeTransferFailed();
        }

        uint256 platformFee = totalAmount * thesisHubConfig.getUint256(ThesisHubConstants.PLATFORM_FEE) / ThesisHubConstants.DENOMINATOR;
        uint256 authorFee = totalAmount - platformFee;
        if (authorFee > 0) {
            (bool authorSuccess,) = payable(_author).call{ value: authorFee }("");
            if (!authorSuccess) revert NativeTransferFailed();
        }
    }
}
