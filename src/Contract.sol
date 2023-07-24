// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

/// @title Zora1155WisdomBuyer
/// @notice A singleton wrapper contract that allows purchases of Zora1155 collections denominated in WisdomERC20
contract Zora1155WisdomBuyer is Ownable {

    struct Price {
        address collection;
        uint256 tokenId;
        uint256 price;
    }

    /// @notice the address of the WisdomERC20 contract
    address public currency;
    /// @notice a mapping of collection addresses to token ids to the price of the token
    mapping(address => mapping(uint256 => uint256)) public prices;

    constructor (address currency_) {
        currency = currency_;
    }

    /// @notice allows the owner of the contract to set the prices of multiple tokens, for multiple collections
    /// @param prices_ an array of Price structs
    function setPrices(Price[] memory prices_) external {
        for (uint256 i = 0; i < prices_.length; i++) {
            prices[prices_[i].collection][prices_[i].tokenId] = prices_[i].price;
        }
    }

}
