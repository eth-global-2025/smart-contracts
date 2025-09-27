// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

library ThesisHubConstants {
    bytes32 public constant DEFAULT_ADMIN_ROLE = 0x0;

    bytes32 public constant TOKEN_FACTORY_ADDRESS = keccak256("TOKEN_FACTORY_ADDRESS");
    bytes32 public constant THESIS_HUB_MASTER_ADDRESS = keccak256("THESIS_HUB_MASTER_ADDRESS");

    uint256 public constant DENOMINATOR = 10_000;
    bytes32 public constant PLATFORM_FEE = keccak256("PLATFORM_FEE");
}
