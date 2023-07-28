// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "zora-1155-contracts/interfaces/IZoraCreator1155.sol";
import { ZoraCreatorFixedPriceSaleStrategy } from "zora-1155-contracts/minters/fixed-price/ZoraCreatorFixedPriceSaleStrategy.sol";
import { LimitedMintPerAddress } from "zora-1155-contracts/minters/utils/LimitedMintPerAddress.sol";

struct ERC20SalesConfig {
    /// @notice The strategy that will be used to determine start and end times for this sale
    ZoraCreatorFixedPriceSaleStrategy wrappedStrategy;
    /// @notice Max tokens that can be minted for an address, 0 if unlimited
    uint64 maxTokensPerAddress;
    /// @notice Price per token in eth wei
    uint96 pricePerToken;
    /// @notice Funds recipient (can't be the zero address)
    address fundsRecipient;
}

/// @notice ZoraCreator1155Wrapper is a wrapper for Zora's ZoraCreator1155 contract
/// @dev The ZoraCreator1155 contract is a fantastic base for 1155 drops, but currently
///      it only supports minting with ETH. This wrapper allows for minting with ERC20 tokens.
///      It does this by using the adminMint function on the token contract. For this to be
///      possible, the token contract must have this wrapper contract as an admin.
contract ZoraCreator1155Wrapper is LimitedMintPerAddress {

    /// @notice The sales configurations for each token
    /// @dev target -> tokenId -> settings
    mapping(address => mapping(uint256 => ERC20SalesConfig)) internal _salesConfigs;
    
    /// @notice allows the owner of the contract to set sale config for a given token
    /// @param tokenId the tokenId
    /// @param salesConfig the salesConfig
    function setSale(IZoraCreator1155 tokenContract, uint256 tokenId, ERC20SalesConfig memory salesConfig) external {
        _salesConfigs[tokenContract][tokenId] = salesConfig;
        if (salesConfig.fundsRecipient == address(0)) {
            revert InvalidFundsRecipient();
        }
        emit ERC20SaleSet(msg.sender, tokenId, salesConfig);
    }
}