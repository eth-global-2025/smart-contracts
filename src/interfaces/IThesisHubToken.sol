// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IThesisHubToken {
    struct TokenInfo {
        string cid;
        string title;
        address author;
        string description;
        uint256 costInNativeInWei;
    }

    error NotOwnerOrThesisHubMaster();

    event CostInNativeInWeiUpdated(uint256 _costInNativeInWei);

    function mint(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
    function setCostInNativeInWei(uint256 _costInNativeInWei) external;
    function costInNativeInWei() external view returns (uint256);
    function cid() external view returns (string memory);
    function title() external view returns (string memory);
    function description() external view returns (string memory);
    function getTokenInfo() external view returns (TokenInfo memory);
}
