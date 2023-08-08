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
    error UserMissingRoleForToken(IZoraCreator1155 tokenContract, address user, uint256 tokenId, uint256 role);

    event ERC20SaleSet(address sender, IZoraCreator1155 tokenContract, uint256 tokenId, ERC20SalesConfig config);
    event ERC20Purchase(
        address sender, IZoraCreator1155 tokenContract, uint256 tokenId, uint256 pricePerToken, address buyer
    );

    /// @notice Modifier checking if the user is an admin or has a role
    /// @dev This reverts if the msg.sender is not an admin for the given token id or contract
    /// @param tokenId tokenId to check
    /// @param role role to check
    modifier onlyAdminOrRole(IZoraCreator1155 tokenContract, uint256 tokenId, uint256 role) {
        if (!tokenContract.isAdminOrRole(msg.sender, tokenId, role)) {
            revert UserMissingRoleForToken(tokenContract, msg.sender, tokenId, role);
        }
        _;
    }

    function contractName() external pure returns (string memory) {
        return "ZoraCreator1155ERC20Wrapper";
    }

    function contractURI() external pure returns (string memory) {
        return "https://github.com/daataart/zora1155-erc20-fixed-price-sale-strategy";
    }

    function contractVersion() external pure returns (string memory) {
        return "1.0.0";
    }

    /// @notice The sales configurations for each token
    /// @dev token contract -> tokenId -> settings
    mapping(address => mapping(uint256 => ERC20SalesConfig)) internal _salesConfigs;

    /// @notice Allows a sender with the Sales or Admin permission on the underlying token contract
    ///         to set sale config for a given tokenId.
    /// @param tokenId the tokenId
    /// @param salesConfig the salesConfig
    function setSale(IZoraCreator1155 tokenContract, uint256 tokenId, ERC20SalesConfig memory salesConfig)
        external
        onlyAdminOrRole(tokenContract, tokenId, tokenContract.PERMISSION_BIT_SALES())
    {
        _salesConfigs[address(tokenContract)][tokenId] = salesConfig;
        if (salesConfig.fundsRecipient == address(0)) {
            revert InvalidFundsRecipient();
        }
        emit ERC20SaleSet(msg.sender, tokenContract, tokenId, salesConfig);
    }

    /// @notice Getter for a token's sales config.
    /// @param tokenContract the token contract
    /// @param tokenId the tokenId
    /// @return the sales config
    function getSale(IZoraCreator1155 tokenContract, uint256 tokenId) external view returns (ERC20SalesConfig memory) {
        return _salesConfigs[address(tokenContract)][tokenId];
    }

    /// @notice Deletes the sale config for a given token.
    /// @param tokenContract the token contract
    /// @param tokenId the tokenId
    function resetSale(IZoraCreator1155 tokenContract, uint256 tokenId)
        external
        onlyAdminOrRole(tokenContract, tokenId, tokenContract.PERMISSION_BIT_SALES())
    {
        delete _salesConfigs[address(tokenContract)][tokenId];
        emit ERC20SaleSet(msg.sender, tokenContract, tokenId, _salesConfigs[address(tokenContract)][tokenId]);
    }

    /// @notice Mint tokens given a token contract and minter arguments.
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

        emit ERC20Purchase(msg.sender, tokenContract, tokenId, internalConfig.pricePerToken, mintTo);
    }
}
