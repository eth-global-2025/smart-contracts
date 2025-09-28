// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

interface IThesisHubToken {
    struct TokenInfo {
        string cid;
        string title;
        address author;
        string description;
        uint256 costInUSD;
    }

    error NotOwnerOrThesisHubMaster();

    event CostUpdated(uint256 _costInUSD);

    function mint(address _to, uint256 _amount) external;
    function burn(uint256 _amount) external;
    function setCostInUSD(uint256 _costInUSD) external;
    function costInUSD() external view returns (uint256);
    function cid() external view returns (string memory);
    function title() external view returns (string memory);
    function description() external view returns (string memory);
    function getTokenInfo() external view returns (TokenInfo memory);
}
