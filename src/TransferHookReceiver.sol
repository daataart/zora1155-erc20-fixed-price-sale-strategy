// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {ITransferHookReceiver} from "zora-1155-contracts/interfaces/ITransferHookReceiver.sol";

/// @title TransferHookReceiver§
/// @notice A contract that implements the ITransferHookReceiver interface

contract TransferHookReceiver is ITransferHookReceiver {
    event TokenTransferBatch(
        address target, address operator, address from, address to, uint256[] ids, uint256[] amount, bytes data
    );

    function onTokenTransferBatch(
        address target,
        address operator,
        address from,
        address to,
        uint256[] memory ids,
        uint256[] memory amounts,
        bytes memory data
    ) external {
        // emit all the data in a single event
        emit TokenTransferBatch(target, operator, from, to, ids, amounts, data);
    }

    function supportsInterface(bytes4 interfaceId) external pure returns (bool) {
        return interfaceId == type(ITransferHookReceiver).interfaceId;
    }
}
