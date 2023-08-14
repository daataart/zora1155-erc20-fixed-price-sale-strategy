// // SPDX-License-Identifier: UNLICENSED
// pragma solidity ^0.8.13;

// import "forge-std/Script.sol";
// import "zora-1155-contracts/interfaces/IZoraCreator1155.sol";
// import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
// import "forge-std/StdUtils.sol";
// import "src/ERC20FixedPriceSaleStrategy.sol";
// import "forge-std/Script.sol";
// import "zora-1155-contracts/minters/fixed-price/ZoraCreatorFixedPriceSaleStrategy.sol";

// address constant WRAPPER_ADDRESS = 0x0000000000000000000000000000000000000000;
// address constant TOKEN_CONTRACT = 0x27f51C07e7D7219C7b3b069726c6c391c35f829e;
// uint256 constant tokenId = 0;
// IERC20 constant wisdomCurrency = IERC20(0xF6b0Dc792B80a781C872B2f0B7787BfE72546B6F);

// contract SetAdminPermissions is Script {
//     function run() external {
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         vm.startBroadcast(deployerPrivateKey);

//         IZoraCreator1155 tokenContract = IZoraCreator1155(TOKEN_CONTRACT);
//         tokenContract.addPermission(tokenId, WRAPPER_ADDRESS, tokenContract.PERMISSION_BIT_ADMIN());

//         vm.stopBroadcast();
//     }
// }

// contract SetSale is Script {
//     function run() external {
//         uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
//         vm.startBroadcast(deployerPrivateKey);
//         address payable alice;
//         IZoraCreator1155 tokenContract = IZoraCreator1155(TOKEN_CONTRACT);

//         tokenContract.callSale(
//             tokenId,
//             WRAPPER_ADDRESS,
//             abi.encodeWithSelector(
//                 ERC20FixedPriceSaleStrategy.setSale.selector,
//                 tokenId,
//                 ERC20FixedPriceSaleStrategy.ERC20SalesConfig({
//                     maxTokensPerAddress: 100,
//                     fundsRecipient: alice,
//                     pricePerToken: 1 ether,
//                     currency: wisdomCurrency
//                 })
//             )
//         );
//         vm.stopBroadcast();
//     }
// }

// // To run this script:
// // source .env && forge script script/SetAdminPermissions.s.sol:SetAdminPermissions --rpc-url $GOERLI_RPC_URL --broadcast -vvvv
