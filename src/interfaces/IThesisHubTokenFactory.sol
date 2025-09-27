// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ThesisHubToken } from "../Token/ThesisHubToken.sol";

interface IThesisHubTokenFactory {
    event ThesisHubConfigUpdated(address _thesisHubConfig);
    event TokenCreated(address _tokenAddress, string _tokenCid);

    function createToken(
        bytes32 _salt,
        string memory _name,
        string memory _symbol,
        ThesisHubToken.TokenInfo memory _tokenInfoParams
    )
        external
        returns (address tokenAddress);

    function updatedThesisHubConfig(address _thesisHubConfig) external;
}
