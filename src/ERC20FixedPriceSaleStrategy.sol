// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "openzeppelin-contracts/contracts/access/Ownable.sol";
import "openzeppelin-contracts/contracts/security/Pausable.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "zora-1155-contracts/interfaces/IZoraCreator1155.sol";
import "zora-1155-contracts/minters/fixed-price/ZoraCreatorFixedPriceSaleStrategy.sol";
import "zora-1155-contracts/minters/SaleStrategy.sol";
import "zora-1155-contracts/minters/utils/LimitedMintPerAddress.sol";

/// @title ERC20FixedPriceSaleStrategy
/// @notice A minter contract that allows purchases of Zora1155 collections denominated in an ERC20.
/// This contract is intended to wrap a ZoraCreatorFixedPriceSaleStrategy contract. It will use the wrapped
/// contract's sales configuration for start/end times, max tokens per address, and funds recipient, but will
/// use the prices set in this contract for the price per token.
contract ERC20FixedPriceSaleStrategy is SaleStrategy, Ownable, Pausable {

    struct ERC20SalesConfig {
        uint64 maxTokensPerAddress;
        address fundsRecipient;
        uint256 price;
        IERC20 currency;
    }

    event ERC20SalesSet(address tokenContract, uint256 tokenId, ERC20SalesConfig config);
    event ERC20Purchase(address tokenContract, uint256 tokenId, uint256 price, address buyer);

    /// target -> tokenId -> settings
    mapping(address => mapping(uint256 => uint256)) internal salesConfigs;

    ZoraCreatorFixedPriceSaleStrategy public wrappedStrategy;

    using SaleCommandHelper for ICreatorCommands.CommandSet;

    constructor (ZoraCreatorFixedPriceSaleStrategy wrappedStrategy_) {
        wrappedStrategy = wrappedStrategy_;
    }

    /// @notice allows the owner of the contract to set the prices of multiple tokens, for multiple collections
    /// @notice setting a price to 0 will disable purchases of that token
    /// @param prices_ an array of Price structs
    function setSales(address tokenContract, uint256[] tokenIds, ERC20SalesConfig[] memory salesConfigs) onlyOwner whenNotPaused external {
        require(tokenIds.length == salesConfigs.length, "Zora1155WisdomBuyer: length mismatch");
        for (uint256 i = 0; i < tokenIds.length; i++) {
            _salesConfigs[tokenContract][tokenIds[i]] = i;
            emit ERC20SalesSet(tokenContract, tokenIds[i], salesConfigs[i]);
        }
    }

    /// @notice Compiles and returns the commands needed to mint a token using this sales strategy
    /// @param tokenId The token ID to mint
    /// @param quantity The quantity of tokens to mint
    /// @param ethValueSent The amount of ETH sent with the transaction
    /// @param minterArguments The arguments passed to the minter, which should be the address to mint to
    function requestMint(
        address,
        uint256 tokenId,
        uint256 quantity,
        uint256,
        bytes calldata minterArguments
    ) external returns (ICreatorCommands.CommandSet memory commands) {
        address mintTo = abi.decode(minterArguments, (address));

        SalesConfig memory externalConfig = wrappedStrategy.salesConfigs()[msg.sender][tokenId];
        ERC20SalesConfig memory internalConfig = salesConfigs[msg.sender][tokenId];

        // If sales config does not exist this first check will always fail.

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
            _requireMintNotOverLimitAndUpdate(internalConfig.maxTokensPerAddress, quantity, msg.sender, tokenId, mintTo);
        }

        address recipient = internalConfig.fundsRecipient == address(0) ? owner() : internalConfig.fundsRecipient;
        commands.setSize(1);

        // Mint command
        commands.mint(mintTo, tokenId, quantity);

        emit ERC20Purchase(msg.sender, tokenId, internalConfig.price, mintTo);

        internalConfig.currency.transferFrom(mintTo, recipient, internalConfig.price);
    }

    /// @notice Deletes the sale config for a given token
    function resetSale(uint256 tokenId) external override {
        delete salesConfigs[msg.sender][tokenId];

        // Deleted sale emit event
        emit SaleSet(msg.sender, tokenId, salesConfigs[msg.sender][tokenId]);
    }

    /// @notice Returns the sale config for a given token
    function sale(address tokenContract, uint256 tokenId) external view returns (SalesConfig memory) {
        return salesConfigs[tokenContract][tokenId];
    }

    function supportsInterface(bytes4 interfaceId) public pure virtual override(LimitedMintPerAddress, SaleStrategy) returns (bool) {
        return super.supportsInterface(interfaceId) || LimitedMintPerAddress.supportsInterface(interfaceId) || SaleStrategy.supportsInterface(interfaceId);
    }
}
