// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "zora-1155-contracts/interfaces/IZoraCreator1155.sol";
import {ZoraCreatorFixedPriceSaleStrategy} from
    "zora-1155-contracts/minters/fixed-price/ZoraCreatorFixedPriceSaleStrategy.sol";
import {LimitedMintPerAddress} from "zora-1155-contracts/minters/utils/LimitedMintPerAddress.sol";
import {PublicMulticall} from "zora-1155-contracts/utils/PublicMulticall.sol";
import {ReentrancyGuardUpgradeable} from "@openzeppelin/contracts-upgradeable/security/ReentrancyGuardUpgradeable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";

/// @notice ZoraCreator1155ERC20Wrapper is a wrapper for Zora's ZoraCreator1155 contract
/// @dev The ZoraCreator1155 contract is a fantastic base for 1155 drops, but currently
///      it only supports minting with ETH. This wrapper allows for minting with ERC20 tokens.
///      It does this by using the adminMint function on the token contract. For this to be
///      possible, the token contract must have this wrapper contract as an admin.
contract ZoraCreator1155ERC20Wrapper is LimitedMintPerAddress, ReentrancyGuardUpgradeable, PublicMulticall {
    struct ERC20SalesConfig {
        /// @notice The strategy that will be used to determine start and end times for this sale
        ZoraCreatorFixedPriceSaleStrategy wrappedStrategy;
        /// @notice Max tokens that can be minted for an address, 0 if unlimited
        uint64 maxTokensPerAddress;
        /// @notice Price per token in eth wei
        uint96 pricePerToken;
        /// @notice The currency used to purchase the token
        IERC20 currency;
        /// @notice Funds recipient (can't be the zero address)
        address fundsRecipient;
    }

    error SaleEnded();
    error SaleHasNotStarted();
    error InvalidFundsRecipient();

    event ERC20SaleSet(address tokenContract, uint256 tokenId, ERC20SalesConfig config);
    event ERC20Purchase(address tokenContract, uint256 tokenId, uint256 pricePerToken, address buyer);

    /// @notice The sales configurations for each token
    /// @dev token contract -> tokenId -> settings
    mapping(address => mapping(uint256 => ERC20SalesConfig)) internal _salesConfigs;

    /// @notice allows the owner of the contract to set sale config for a given token
    /// @param tokenId the tokenId
    /// @param salesConfig the salesConfig
    function setSale(IZoraCreator1155 tokenContract, uint256 tokenId, ERC20SalesConfig memory salesConfig) external {
        _salesConfigs[address(tokenContract)][tokenId] = salesConfig;
        if (salesConfig.fundsRecipient == address(0)) {
            revert InvalidFundsRecipient();
        }
        emit ERC20SaleSet(msg.sender, tokenId, salesConfig);
    }

    /// @notice getter for a token's sales config
    /// @param tokenContract the token contract
    /// @param tokenId the tokenId
    /// @return the sales config
    function getSale(IZoraCreator1155 tokenContract, uint256 tokenId) external view returns (ERC20SalesConfig memory) {
        return _salesConfigs[address(tokenContract)][tokenId];
    }

    /// @notice Mint tokens given a token contract and minter arguments
    /// @param tokenContract The token contract to mint
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    /// @param mintTo The address to mint to
    function mint(IZoraCreator1155 tokenContract, uint256 tokenId, uint256 quantity, address mintTo)
        external
        nonReentrant
    {
        ERC20SalesConfig memory internalConfig = _salesConfigs[address(tokenContract)][tokenId];
        ZoraCreatorFixedPriceSaleStrategy.SalesConfig memory externalConfig =
            internalConfig.wrappedStrategy.sale(address(tokenContract), tokenId);

        // If a sales config does not exist on the wrapped strategy, this check will fail
        // Check sale end
        if (block.timestamp > externalConfig.saleEnd) {
            revert SaleEnded();
        }

        // Check sale start
        if (block.timestamp < externalConfig.saleStart) {
            revert SaleHasNotStarted();
        }

        // Check minted per address limit
        if (internalConfig.maxTokensPerAddress > 0) {
            _requireMintNotOverLimitAndUpdate(
                internalConfig.maxTokensPerAddress, quantity, address(tokenContract), tokenId, mintTo
            );
        }

        // Mint command
        tokenContract.adminMint(mintTo, tokenId, quantity, new bytes(0));

        // If an ERC20 sales config doesn't exist, this will fail
        internalConfig.currency.transferFrom(
            msg.sender, internalConfig.fundsRecipient, internalConfig.pricePerToken * quantity
        );

        emit ERC20Purchase(msg.sender, tokenId, internalConfig.pricePerToken, mintTo);
    }
}
