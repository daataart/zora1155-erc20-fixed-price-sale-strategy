// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.13;

import "forge-std/Script.sol";
import "zora-1155-contracts/interfaces/IZoraCreator1155.sol";

address constant WRAPPER_ADDRESS = 0x0000000000000000000000000000000000000000;
address constant TOKEN_CONTRACT = 0x0000000000000000000000000000000000000000;
uint256 constant tokenId = 0;

contract SetAdminPermissions is Script {
    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(deployerPrivateKey);

        IZoraCreator1155 tokenContract = IZoraCreator1155(TOKEN_CONTRACT);
        tokenContract.addPermission(tokenId, WRAPPER_ADDRESS, tokenContract.PERMISSION_BIT_ADMIN());

        vm.stopBroadcast();
    }
}

// To run this script:
// source .env && forge script script/SetAdminPermissions.s.sol:SetAdminPermissions --rpc-url $GOERLI_RPC_URL --broadcast -vvvv
