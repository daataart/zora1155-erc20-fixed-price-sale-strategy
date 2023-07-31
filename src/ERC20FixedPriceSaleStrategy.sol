// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

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
contract ERC20FixedPriceSaleStrategy is SaleStrategy, LimitedMintPerAddress {
    struct ERC20SalesConfig {
        uint64 maxTokensPerAddress;
        address fundsRecipient;
        uint256 pricePerToken;
        IERC20 currency;
    }

    error SaleEnded();
    error SaleHasNotStarted();
    error WrongValueSent();
    error InvalidFundsRecipient();

    event ERC20SaleSet(address tokenContract, uint256 tokenId, ERC20SalesConfig config);
    event ERC20Purchase(address tokenContract, uint256 tokenId, uint256 pricePerToken, address buyer);

    /// target -> tokenId -> settings
    mapping(address => mapping(uint256 => ERC20SalesConfig)) internal _salesConfigs;

    ZoraCreatorFixedPriceSaleStrategy public wrappedStrategy;

    using SaleCommandHelper for ICreatorCommands.CommandSet;

    constructor(ZoraCreatorFixedPriceSaleStrategy wrappedStrategy_) {
        wrappedStrategy = wrappedStrategy_;
    }

    function contractName() external pure returns (string memory) {
        return "ERC20FixedPriceSaleStrategy";
    }

    function contractURI() external pure returns (string memory) {
        return "https://github.com/daataart/zora1155-erc20-fixed-price-sale-strategy";
    }

    function contractVersion() external pure returns (string memory) {
        return "1.0.0";
    }

    /// @notice allows the owner of the contract to set sale config for a given token
    /// @param tokenId the tokenId
    /// @param salesConfig the salesConfig
    function setSale(uint256 tokenId, ERC20SalesConfig memory salesConfig) external {
        _salesConfigs[msg.sender][tokenId] = salesConfig;
        if (salesConfig.fundsRecipient == address(0)) {
            revert InvalidFundsRecipient();
        }
        emit ERC20SaleSet(msg.sender, tokenId, salesConfig);
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
        uint256 ethValueSent,
        bytes calldata minterArguments
    ) external returns (ICreatorCommands.CommandSet memory commands) {
        address mintTo = abi.decode(minterArguments, (address));

        ZoraCreatorFixedPriceSaleStrategy.SalesConfig memory externalConfig = wrappedStrategy.sale(msg.sender, tokenId);
        ERC20SalesConfig memory internalConfig = _salesConfigs[msg.sender][tokenId];

        // If a sales config does not exist on the wrapped strategy, this check will fail
        // Check sale end
        if (block.timestamp > externalConfig.saleEnd) {
            revert SaleEnded();
        }

        // Check sale start
        if (block.timestamp < externalConfig.saleStart) {
            revert SaleHasNotStarted();
        }

        // Value sent should be 0 here, otherwise eth will be trapped
        if (ethValueSent > 0) {
            revert WrongValueSent();
        }

        // Check minted per address limit
        if (internalConfig.maxTokensPerAddress > 0) {
            _requireMintNotOverLimitAndUpdate(internalConfig.maxTokensPerAddress, quantity, msg.sender, tokenId, mintTo);
        }

        address recipient = internalConfig.fundsRecipient;
        commands.setSize(1);

        // Mint command
        commands.mint(mintTo, tokenId, quantity);

        // If an ERC20 sales config doesn't exist, this will fail
        internalConfig.currency.transferFrom(mintTo, recipient, internalConfig.pricePerToken * quantity);

        emit ERC20Purchase(msg.sender, tokenId, internalConfig.pricePerToken, mintTo);
    }

    /// @notice Deletes the sale config for a given token
    function resetSale(uint256 tokenId) external override {
        delete _salesConfigs[msg.sender][tokenId];

        // Deleted sale emit event
        emit ERC20SaleSet(msg.sender, tokenId, _salesConfigs[msg.sender][tokenId]);
    }

    /// @notice Returns the sale config for a given token
    function sale(address tokenContract, uint256 tokenId) external view returns (ERC20SalesConfig memory) {
        return _salesConfigs[tokenContract][tokenId];
    }

    function supportsInterface(bytes4 interfaceId)
        public
        pure
        virtual
        override(LimitedMintPerAddress, SaleStrategy)
        returns (bool)
    {
        return super.supportsInterface(interfaceId) || LimitedMintPerAddress.supportsInterface(interfaceId)
            || SaleStrategy.supportsInterface(interfaceId);
    }
}
