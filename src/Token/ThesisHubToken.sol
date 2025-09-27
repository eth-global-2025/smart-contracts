// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { Ownable } from "@openzeppelin/contracts/access/Ownable.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { SafeERC20 } from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import { IThesisHubToken } from "../interfaces/IThesisHubToken.sol";
import { IThesisHubConfig } from "../interfaces/IThesisHubConfig.sol";
import { ThesisHubConstants } from "../utils/ThesisHubConstants.sol";
import { IThesisHubMaster } from "../interfaces/IThesisHubMaster.sol";

contract ThesisHubToken is ERC20, IThesisHubToken, Ownable {
    using SafeERC20 for ERC20;

    string public cid;
    string public title;
    string public description;
    uint256 public costInNativeInWei;
    
    IThesisHubConfig public thesisHubConfig;

    constructor(
        string memory name,
        string memory symbol,
        IThesisHubToken.TokenInfo memory _tokenInfoParams,
        address _thesisHubConfig
    )
        ERC20(name, symbol)
        Ownable(_tokenInfoParams.author)
    {
        cid = _tokenInfoParams.cid;
        title = _tokenInfoParams.title;
        description = _tokenInfoParams.description;
        costInNativeInWei = _tokenInfoParams.costInNativeInWei;
        thesisHubConfig = IThesisHubConfig(_thesisHubConfig);
    }

    modifier onlyOwnerOrThesisHubMaster() {
        if (msg.sender != owner() && msg.sender != thesisHubConfig.getAddress(ThesisHubConstants.THESIS_HUB_MASTER_ADDRESS)) {
            revert NotOwnerOrThesisHubMaster();
        }
        _;
    }

    function getTokenInfo() external view returns (TokenInfo memory) {
        return TokenInfo({
            cid: cid,
            title: title,
            description: description,
            costInNativeInWei: costInNativeInWei,
            author: owner()
        });
    }

    function mint(address _to, uint256 _amount) external onlyOwnerOrThesisHubMaster {
        _update(address(0), _to, _amount);
    }

    function burn(uint256 _amount) external {
        _update(msg.sender, address(0), _amount);
    }

    function setCostInNativeInWei(uint256 _costInNativeInWei) external onlyOwner {
        costInNativeInWei = _costInNativeInWei;

        emit CostInNativeInWeiUpdated(costInNativeInWei);
    }

    function _update(address from, address to, uint256 amount) internal override {
        address thesisHubMaster = thesisHubConfig.getAddress(ThesisHubConstants.THESIS_HUB_MASTER_ADDRESS);
        IThesisHubMaster(thesisHubMaster).beforeTokenTransfer(from, to, amount);
        super._update(from, to, amount);
    }
}
