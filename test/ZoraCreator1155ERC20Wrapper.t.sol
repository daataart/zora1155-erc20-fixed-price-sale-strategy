// // SPDX-License-Identifier: Unlicense
// pragma solidity ^0.8.13;

// import {Test, Vm} from "forge-std/Test.sol";
// import "src/ZoraCreator1155ERC20Wrapper.sol";
// import "zora-1155-contracts/interfaces/IZoraCreator1155Factory.sol";
// import "zora-1155-contracts/interfaces/IZoraCreator1155.sol";
// import {ZoraCreatorFixedPriceSaleStrategy} from
//     "zora-1155-contracts/minters/fixed-price/ZoraCreatorFixedPriceSaleStrategy.sol";
// import {ILimitedMintPerAddress} from "zora-1155-contracts/interfaces/ILimitedMintPerAddress.sol";

// import "zora-1155-contracts/interfaces/ICreatorRoyaltiesControl.sol";
// import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
// import "forge-std/StdUtils.sol";

// // factory: This is a constant variable that is assigned the address where the IZoraCreator1155Factory contract is deployed.
// IZoraCreator1155Factory constant factory = IZoraCreator1155Factory(0xA6C5f2DE915240270DaC655152C3f6A91748cb85);
// // wrappedStrategy: This is a constant variable that is assigned the address where the ZoraCreatorFixedPriceSaleStrategy contract is deployed.
// ZoraCreatorFixedPriceSaleStrategy constant wrappedStrategy =
//     ZoraCreatorFixedPriceSaleStrategy(0x5Ff5a77dD2214d863aCA809C0168941052d9b180);
// // wisdomCurrency: This is a constant variable that is assigned the address where the wisdomCurrency ERC20 token contract is deployed.
// // by defining this as an IERC20, we can call the ERC20 functions on this contract.
// IERC20 constant wisdomCurrency = IERC20(0xF6b0Dc792B80a781C872B2f0B7787BfE72546B6F);
// IERC20 constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
// address constant zoraFeesTreasury = address(0xd1d1D4e36117aB794ec5d4c78cBD3a8904E691D0);
// uint256 constant ZORA_MINT_FEE = 0.000777 ether;

// contract TestZoraCreator1155ERC20Wrapper is Test {
//     // Define a variable to hold the wrapper strategy
//     ZoraCreator1155ERC20Wrapper wrapper;
//     // Define an address for testing
//     address payable alice;
//     address payable bob;
//     address payable gav;

//     function setUp() public {
//         // Create a new instance of the wrapper strategy, at the moment of setup, it is identical to the wrapped strategy (Zora Create Fixed Price Sale Strategy)
//         wrapper = new ZoraCreator1155ERC20Wrapper();
//         // Make mock addresses for the tests
//         alice = payable(makeAddr("alice"));
//         bob = payable(makeAddr("bob"));
//         gav = payable(makeAddr("gav"));
//     }

//     function test_WrapperMintFlow() public {
//         vm.startPrank(alice);
//         //A dynamic array of bytes named actions is created with a size of 0. This array is used to store actions, but in this case, it is initialized as an empty array.
//         bytes[] memory actions = new bytes[](0);
//         // The createContract function is called on the factory contract, which creates a new Zora collection. The function takes the following parameters:
//         // name: The name of the collection.
//         // symbol: The symbol of the collection.
//         // royalty: The royalty configuration of the collection.
//         // creator: The address of the creator of the collection.
//         // actions: The actions that are to be performed on the collection.
//         address _tokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );
//         // The address of the new collection (_tokenContract) is assigned to the variable tokenContract.
//         IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);
//         // set up a new token, setupNewToken takes two parameters:
//         // tokenURI: The URI of the token.
//         // supply: The supply of the token.
//         uint256 newTokenId = tokenContract.setupNewToken("", 100);

//         // give the wrappedStrategy and the wrapper the minter role
//         // this is the original Strategy from Zora
//         tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         // this is the wrapper - we need to give the wrapper the admin permmission
//         tokenContract.addPermission(1, address(wrapper), tokenContract.PERMISSION_BIT_ADMIN());

//         // call the wrapped strategy to set up the sale
//         tokenContract.callSale(
//             newTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 newTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 0,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );

//         // call the wrapper strategy to set up the sale
//         wrapper.setSale(
//             tokenContract,
//             newTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );

//         vm.stopPrank();

//         vm.startPrank(bob);
//         deal(address(wisdomCurrency), bob, 1 ether);
//         deal(bob, 1 ether);

//         wisdomCurrency.approve(address(wrapper), 1 ether);

//         wrapper.mint(tokenContract, newTokenId, 1, bob);

//         assertEq(wisdomCurrency.balanceOf(address(alice)), 1 ether);
//         assertEq(wisdomCurrency.balanceOf(address(bob)), 0 ether);
//         assertEq(tokenContract.balanceOf(bob, 1), 1);
//     }

//     function test_WrapperSaleStart() external {
//         // create a new zora collection from the factory

//         vm.startPrank(alice);
//         bytes[] memory actions = new bytes[](0);
//         address _tokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );
//         IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);
//         // set up a new token
//         uint256 newTokenId = tokenContract.setupNewToken("", 100);

//         // give the wrappedStrategy and the wrapper the minter role
//         // this is the original Strategy from Zora
//         tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         // this is the new Strategy
//         tokenContract.addPermission(1, address(wrapper), tokenContract.PERMISSION_BIT_MINTER());

//         // call the wrapped strategy to set up the sale
//         tokenContract.callSale(
//             newTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 newTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: uint64(block.timestamp + 1 days),
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 0,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );

//         // call the wrapper strategy to set up the sale
//         wrapper.setSale(
//             tokenContract,
//             newTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );

//         vm.stopPrank();

//         vm.deal(bob, 20 ether);

//         vm.expectRevert(abi.encodeWithSignature("SaleHasNotStarted()"));
//         vm.prank(bob);
//         wrapper.mint(tokenContract, newTokenId, 10, bob);
//     }

//     function test_SaleEnd() external {
//         // create a new zora collection from the factory

//         vm.startPrank(alice);
//         bytes[] memory actions = new bytes[](0);
//         address _tokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );
//         IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);
//         // set up a new token
//         uint256 newTokenId = tokenContract.setupNewToken("", 100);

//         // give the wrappedStrategy and the wrapper the minter role
//         // this is the original Strategy from Zora
//         tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         // this is the new Strategy
//         tokenContract.addPermission(1, address(wrapper), tokenContract.PERMISSION_BIT_MINTER());

//         // call the wrapped strategy to set up the sale
//         tokenContract.callSale(
//             newTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 newTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: 0,
//                     saleEnd: uint64(1 days),
//                     maxTokensPerAddress: 0,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );

//         // call the wrapper strategy to set up the sale
//         wrapper.setSale(
//             tokenContract,
//             newTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );

//         vm.stopPrank();

//         vm.deal(bob, 20 ether);
//         vm.expectRevert(abi.encodeWithSignature("SaleEnded()"));
//         vm.prank(bob);
//         wrapper.mint(tokenContract, newTokenId, 10, bob);
//     }

//     function test_MaxTokensPerAddress() external {
//         // create a new zora collection from the factory

//         vm.startPrank(alice);
//         bytes[] memory actions = new bytes[](0);
//         address _tokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );
//         IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);
//         // set up a new token
//         uint256 newTokenId = tokenContract.setupNewToken("", 100);

//         // give the wrappedStrategy and the wrapperStrategy the minter role
//         // this is the original Strategy from Zora
//         tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         // this is the new Strategy
//         tokenContract.addPermission(1, address(wrapper), tokenContract.PERMISSION_BIT_MINTER());

//         // call the wrapped strategy to set up the sale
//         tokenContract.callSale(
//             newTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 newTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: 0,
//                     saleEnd: uint64(1 days),
//                     maxTokensPerAddress: 1,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );

//         // call the wrapper strategy to set up the sale
//         wrapper.setSale(
//             tokenContract,
//             newTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 1,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );

//         vm.stopPrank();

//         vm.warp(0.5 days);

//         vm.deal(bob, 20 ether);
//         deal(address(wisdomCurrency), bob, 1 ether);

//         wisdomCurrency.approve(address(wrapper), 1 ether);

//         vm.expectRevert(abi.encodeWithSelector(ILimitedMintPerAddress.UserExceedsMintLimit.selector, bob, 1, 6));
//         vm.prank(bob);

//         // bob mints from the tokenContract
//         // the mint function takes the following parameters:
//         //value: The amount of ether to send with the transaction.
//         // to: The address of the recipient of the token.
//         // tokenId: The ID of the token.
//         // amount: The amount of tokens to mint.
//         // data: The data to be passed to the token contract.
//         wrapper.mint(tokenContract, newTokenId, 6, bob);
//     }

//     function test_SaleForDifferentERC20s() external {
//         uint256 initialWisdomBalance = wisdomCurrency.balanceOf(alice);
//         uint256 initialUsdcBalance = usdc.balanceOf(alice);
//         vm.startPrank(alice);
//         //A dynamic array of bytes named actions is created with a size of 0. This array is used to store actions, but in this case, it is initialized as an empty array.
//         bytes[] memory actions = new bytes[](0);
//         // The createContract function is called on the factory contract, which creates a new Zora collection. The function takes the following parameters:
//         // name: The name of the collection.
//         // symbol: The symbol of the collection.
//         // royalty: The royalty configuration of the collection.
//         // creator: The address of the creator of the collection.
//         // actions: The actions that are to be performed on the collection.
//         address _tokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );
//         // The address of the new collection (_tokenContract) is assigned to the variable tokenContract.
//         IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);
//         // set up a new token, setupNewToken takes two parameters:
//         // tokenURI: The URI of the token.
//         // supply: The supply of the token.
//         uint256 firstTokenId = tokenContract.setupNewToken("", 100);
//         uint256 secondTokenId = tokenContract.setupNewToken("", 100);

//         // give the wrappedStrategy and the wrapperStrategy the minter role
//         // this is the original Strategy from Zora
//         tokenContract.addPermission(firstTokenId, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         // this is the new Strategy
//         tokenContract.addPermission(firstTokenId, address(wrapper), tokenContract.PERMISSION_BIT_MINTER());
//         tokenContract.addPermission(secondTokenId, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         // this is the new Strategy
//         tokenContract.addPermission(secondTokenId, address(wrapper), tokenContract.PERMISSION_BIT_MINTER());

//         // call the wrapped strategy to set up the sale
//         tokenContract.callSale(
//             firstTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 firstTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 0,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );

//         tokenContract.callSale(
//             secondTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 secondTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 0,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );
//         wrapper.setSale(
//             tokenContract,
//             firstTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );

//         wrapper.setSale(
//             tokenContract,
//             secondTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: usdc
//             })
//         );

//         vm.stopPrank();

//         vm.startPrank(bob);
//         deal(address(wisdomCurrency), bob, 1 ether);
//         deal(address(usdc), bob, 1 ether);
//         deal(bob, 1 ether);

//         wisdomCurrency.approve(address(wrapper), 1 ether);
//         usdc.approve(address(wrapper), 1 ether);

//         // bob mints from the tokenContract
//         // the mint function takes the following parameters:
//         // to: The address of the recipient of the token.
//         // tokenId: The ID of the token.
//         // amount: The amount of tokens to mint.
//         // data: The data to be passed to the token contract.

//         wrapper.mint(tokenContract, 1, 1, bob);
//         wrapper.mint(tokenContract, 2, 1, bob);

//         assertEq(wisdomCurrency.balanceOf(address(alice)), initialWisdomBalance + 1 ether);
//         assertEq(usdc.balanceOf(address(alice)), initialUsdcBalance + 1 ether);

//         assertEq(wisdomCurrency.balanceOf(address(bob)), 0 ether);
//         assertEq(usdc.balanceOf(address(bob)), 0 ether);

//         assertEq(tokenContract.balanceOf(bob, 1), 1);
//         assertEq(tokenContract.balanceOf(bob, 2), 1);
//     }

//     function test_SaleForDifferentContracts() external {
//         uint256 initialWisdomBalance = wisdomCurrency.balanceOf(alice);
//         uint256 initialUsdcBalance = usdc.balanceOf(alice);
//         vm.startPrank(alice);
//         bytes[] memory actions = new bytes[](0);
//         address _firstTokenContract = factory.createContract(
//             "firstTest", "test1", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );
//         address _secondTokenContract = factory.createContract(
//             "secondTest", "test2", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );
//         IZoraCreator1155 firstTokenContract = IZoraCreator1155(_firstTokenContract);
//         IZoraCreator1155 secondTokenContract = IZoraCreator1155(_secondTokenContract);

//         uint256 firstTokenId = firstTokenContract.setupNewToken("", 100);
//         uint256 secondTokenId = secondTokenContract.setupNewToken("", 100);

//         firstTokenContract.addPermission(
//             firstTokenId, address(wrappedStrategy), firstTokenContract.PERMISSION_BIT_MINTER()
//         );
//         firstTokenContract.addPermission(firstTokenId, address(wrapper), firstTokenContract.PERMISSION_BIT_MINTER());

//         secondTokenContract.addPermission(
//             secondTokenId, address(wrappedStrategy), secondTokenContract.PERMISSION_BIT_MINTER()
//         );

//         secondTokenContract.addPermission(secondTokenId, address(wrapper), secondTokenContract.PERMISSION_BIT_MINTER());

//         firstTokenContract.callSale(
//             firstTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 firstTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 0,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );

//         secondTokenContract.callSale(
//             secondTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 secondTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 0,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );

//         wrapper.setSale(
//             firstTokenContract,
//             firstTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );

//         wrapper.setSale(
//             secondTokenContract,
//             secondTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: usdc
//             })
//         );
//         vm.stopPrank();

//         vm.startPrank(bob);
//         deal(address(wisdomCurrency), bob, 1 ether);
//         deal(address(usdc), bob, 1 ether);
//         deal(bob, 1 ether);

//         wisdomCurrency.approve(address(wrapper), 1 ether);
//         usdc.approve(address(wrapper), 1 ether);

//         wrapper.mint(firstTokenContract, firstTokenId, 1, bob);
//         wrapper.mint(secondTokenContract, secondTokenId, 1, bob);

//         assertEq(wisdomCurrency.balanceOf(address(alice)), initialWisdomBalance + 1 ether);
//         assertEq(usdc.balanceOf(address(alice)), initialUsdcBalance + 1 ether);

//         assertEq(wisdomCurrency.balanceOf(address(bob)), 0 ether);
//         assertEq(usdc.balanceOf(address(bob)), 0 ether);

//         assertEq(firstTokenContract.balanceOf(bob, firstTokenId), 1);
//         assertEq(secondTokenContract.balanceOf(bob, secondTokenId), 1);
//     }

//     function test_MultipleRecipientsAndERC20s() external {
//         uint256 initialWisdomBalanceAlice = wisdomCurrency.balanceOf(alice);
//         uint256 initialUsdcBalanceAlice = usdc.balanceOf(alice);
//         uint256 initialWisdomBalanceGav = wisdomCurrency.balanceOf(gav);
//         uint256 initialUsdcBalanceGav = usdc.balanceOf(gav);
//         vm.startPrank(alice);

//         bytes[] memory actions = new bytes[](0);

//         address _firstTokenContract = factory.createContract(
//             "firstTest", "test1", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );
//         address _secondTokenContract = factory.createContract(
//             "secondTest", "test2", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );

//         IZoraCreator1155 firstTokenContract = IZoraCreator1155(_firstTokenContract);
//         IZoraCreator1155 secondTokenContract = IZoraCreator1155(_secondTokenContract);

//         uint256 firstTokenId = firstTokenContract.setupNewToken("", 100);
//         uint256 secondTokenId = secondTokenContract.setupNewToken("", 100);

//         firstTokenContract.addPermission(
//             firstTokenId, address(wrappedStrategy), firstTokenContract.PERMISSION_BIT_MINTER()
//         );
//         firstTokenContract.addPermission(firstTokenId, address(wrapper), firstTokenContract.PERMISSION_BIT_MINTER());
//         secondTokenContract.addPermission(
//             secondTokenId, address(wrappedStrategy), secondTokenContract.PERMISSION_BIT_MINTER()
//         );
//         secondTokenContract.addPermission(secondTokenId, address(wrapper), secondTokenContract.PERMISSION_BIT_MINTER());

//         firstTokenContract.callSale(
//             firstTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 firstTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 0,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );

//         secondTokenContract.callSale(
//             secondTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 secondTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 0,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );

//         wrapper.setSale(
//             firstTokenContract,
//             firstTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );

//         wrapper.setSale(
//             secondTokenContract,
//             secondTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: gav,
//                 pricePerToken: 1 ether,
//                 currency: usdc
//             })
//         );

//         vm.stopPrank();

//         vm.startPrank(bob);
//         deal(address(wisdomCurrency), bob, 1 ether);
//         deal(address(usdc), bob, 1 ether);
//         deal(bob, 1 ether);

//         wisdomCurrency.approve(address(wrapper), 1 ether);
//         usdc.approve(address(wrapper), 1 ether);

//         wrapper.mint(firstTokenContract, firstTokenId, 1, bob);
//         wrapper.mint(secondTokenContract, secondTokenId, 1, bob);

//         // Alice only gained $wisdomCurrency
//         assertEq(wisdomCurrency.balanceOf(address(alice)), initialWisdomBalanceAlice + 1 ether);
//         assertEq(usdc.balanceOf(address(alice)), initialUsdcBalanceAlice);

//         // Gav only gained USDC
//         assertEq(usdc.balanceOf(address(gav)), initialUsdcBalanceGav + 1 ether);
//         assertEq(wisdomCurrency.balanceOf(address(gav)), initialWisdomBalanceGav);

//         assertEq(wisdomCurrency.balanceOf(address(bob)), 0 ether);
//         assertEq(usdc.balanceOf(address(bob)), 0 ether);

//         assertEq(firstTokenContract.balanceOf(bob, firstTokenId), 1);
//         assertEq(secondTokenContract.balanceOf(bob, secondTokenId), 1);
//     }

//     function test_CostAmountsMuliplyCorrectly(uint64 quantity, uint96 pricePerToken) public {
//         vm.assume(quantity > 0);
//         uint96 total;
//         assembly ("memory-safe") {
//             total := mul(pricePerToken, quantity)
//         }
//         emit log_named_uint("pricePerToken", pricePerToken);
//         emit log_named_uint("total / quantity", total / quantity);
//         vm.assume(pricePerToken == total / quantity);

//         vm.startPrank(alice);
//         bytes[] memory actions = new bytes[](0);
//         address _tokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );
//         IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);
//         uint256 newTokenId = tokenContract.setupNewToken("", type(uint256).max);
//         tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         tokenContract.addPermission(1, address(wrapper), tokenContract.PERMISSION_BIT_MINTER());

//         // call the wrapped strategy to set up the sale
//         tokenContract.callSale(
//             newTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 newTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 0,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );

//         wrapper.setSale(
//             tokenContract,
//             newTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: type(uint64).max,
//                 fundsRecipient: alice,
//                 pricePerToken: pricePerToken,
//                 currency: wisdomCurrency
//             })
//         );

//         vm.stopPrank();

//         vm.startPrank(bob);
//         deal(address(wisdomCurrency), bob, quantity * pricePerToken);
//         deal(bob, quantity * ZORA_MINT_FEE);

//         wisdomCurrency.approve(address(wrapper), quantity * pricePerToken);

//         wrapper.mint(tokenContract, newTokenId, quantity, bob);

//         assertEq(tokenContract.balanceOf(bob, 1), quantity);
//         assertEq(wisdomCurrency.balanceOf(address(alice)), quantity * pricePerToken);
//         assertEq(wisdomCurrency.balanceOf(address(bob)), 0 ether);
//     }

//     function test_ResetSale() external {
//         vm.startPrank(alice);
//         bytes[] memory actions = new bytes[](0);
//         address _tokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );
//         IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);
//         // set up a new token
//         uint256 newTokenId = tokenContract.setupNewToken("", 100);

//         // give the wrappedStrategy and the wrapperStrategy the minter role
//         // this is the original Strategy from Zora
//         tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         // this is the new Strategy

//         tokenContract.addPermission(1, address(wrapper), tokenContract.PERMISSION_BIT_MINTER());
//         // vm.expectEmit(false, false, false, false);

//         // call the wrapped strategy to set up the sale
//         tokenContract.callSale(
//             newTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 newTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 0,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );
//         // vm.expectEmit(false, false, false, false);

//         wrapper.setSale(
//             tokenContract,
//             newTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: type(uint64).max,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );

//         wrapper.resetSale(tokenContract, newTokenId);

//         vm.stopPrank();

//         ZoraCreator1155ERC20Wrapper.ERC20SalesConfig memory sale = wrapper.getSale(tokenContract, newTokenId);
//         assertEq(sale.pricePerToken, 0);
//         assertEq(sale.maxTokensPerAddress, 0);
//         assertEq(sale.fundsRecipient, address(0));

//         // Check that the original ETH denominated sale strategy is still in place
//         ZoraCreatorFixedPriceSaleStrategy.SalesConfig memory ethSale =
//             wrappedStrategy.sale(address(tokenContract), newTokenId);
//         assertEq(ethSale.pricePerToken, 1 ether);
//         assertEq(ethSale.saleStart, 0);
//         assertEq(ethSale.saleEnd, type(uint64).max);
//         assertEq(ethSale.maxTokensPerAddress, 0);
//         assertEq(ethSale.fundsRecipient, address(0));

//         // Test that you get a revert when you try to mint a token for an ERC20
//         vm.startPrank(bob);
//         deal(address(wisdomCurrency), bob, 1 ether);
//         deal(bob, 1 ether);

//         wisdomCurrency.approve(address(wrapper), 1 ether);

//         vm.expectRevert();
//         wrapper.mint(tokenContract, 1, 1, bob);
//         vm.stopPrank();
//     }

//     function test_ZoraFeeIsRespectedETH() public {
//         uint256 aliceBalance = wisdomCurrency.balanceOf(alice);
//         uint256 bobBalance = wisdomCurrency.balanceOf(bob);
//         uint256 initialTreasureBalance = address(zoraFeesTreasury).balance;

//         vm.startPrank(alice);

//         bytes[] memory actions = new bytes[](0);

//         address _tokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );

//         IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);

//         uint256 newTokenId = tokenContract.setupNewToken("", 100);

//         tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         tokenContract.addPermission(1, address(wrapper), tokenContract.PERMISSION_BIT_MINTER());

//         tokenContract.callSale(
//             newTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 newTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 0.1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 1,
//                     fundsRecipient: alice
//                 })
//             )
//         );
//         wrapper.setSale(
//             tokenContract,
//             newTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );

//         vm.stopPrank();

//         vm.startPrank(bob);
//         deal(address(wisdomCurrency), bob, 1 ether);
//         deal(bob, 1 ether);
//         uint256 bobEthBalance = address(bob).balance;

//         wisdomCurrency.approve(address(wrapper), 1 ether);

//         // Mint for ETH using the wrapped strategy
//         tokenContract.mint{value: 0.1 ether + ZORA_MINT_FEE}(wrappedStrategy, 1, 1, abi.encode(bob));

//         // Bob gets a token
//         assertEq(tokenContract.balanceOf(bob, 1), 1);
//         // Zora gets a fee
//         assertEq(address(zoraFeesTreasury).balance, initialTreasureBalance + ZORA_MINT_FEE);
//         // Bob pays the fee
//         assertEq(address(bob).balance, bobEthBalance - 0.1 ether - ZORA_MINT_FEE);
//         // alice gets the rest
//         assertEq(address(alice).balance, 0.1 ether);
//     }

//     function test_ZoraFeeIsRespectedWisdom() public {
//         uint256 aliceBalance = wisdomCurrency.balanceOf(alice);
//         uint256 bobBalance = wisdomCurrency.balanceOf(bob);
//         uint256 initialTreasureBalance = address(zoraFeesTreasury).balance;

//         vm.startPrank(alice);

//         bytes[] memory actions = new bytes[](0);

//         address _tokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );

//         IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);

//         uint256 newTokenId = tokenContract.setupNewToken("", 100);

//         tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         tokenContract.addPermission(1, address(wrapper), tokenContract.PERMISSION_BIT_MINTER());

//         tokenContract.callSale(
//             newTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 newTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 0.1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 1,
//                     fundsRecipient: alice
//                 })
//             )
//         );

//         wrapper.setSale(
//             tokenContract,
//             newTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );
//         vm.stopPrank();

//         vm.startPrank(bob);
//         deal(address(wisdomCurrency), bob, 3 ether);
//         deal(bob, 1 ether);
//         uint256 bobEthBalance = address(bob).balance;
//         uint256 quantity = 3;
//         uint256 pricePerToken = 1 ether;
//         wisdomCurrency.approve(address(wrapper), pricePerToken * quantity);
//         // tokenContract.mint{value: 0.1 ether}(wrapperStrategy, 1, 1, abi.encode(bob));
//         // Mint for wisdom using the wrapper strategy
//         // wrapper.mint{value: ZORA_MINT_FEE * quantity}(wrapper, newTokenId, quantity, abi.encode(bob));
//         wrapper.mint(tokenContract, newTokenId, quantity, bob);
//         // the wisdom currency changes hands
//         assertEq(wisdomCurrency.balanceOf(address(alice)), 3 ether);
//         assertEq(wisdomCurrency.balanceOf(address(bob)), 0 ether);

//         // Bob gets a token
//         assertEq(tokenContract.balanceOf(bob, 1), 3);
//         // Zora gets a fee
//         // assertEq(address(zoraFeesTreasury).balance, initialTreasureBalance + (ZORA_MINT_FEE * quantity));
//         // Bob pays the fee
//         assertEq(address(bob).balance, bobEthBalance);
//     }

//     function test_ZeroAddressAsFundsRecipient() public {
//         uint256 aliceBalance = wisdomCurrency.balanceOf(alice);
//         uint256 bobBalance = wisdomCurrency.balanceOf(bob);
//         uint256 initialTreasureBalance = address(zoraFeesTreasury).balance;

//         vm.startPrank(alice);

//         bytes[] memory actions = new bytes[](0);

//         address _tokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );

//         IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);

//         uint256 newTokenId = tokenContract.setupNewToken("", 100);

//         tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         tokenContract.addPermission(1, address(wrapper), tokenContract.PERMISSION_BIT_MINTER());

//         tokenContract.callSale(
//             newTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 newTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 0.1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 1,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );

//         vm.expectRevert();

//         wrapper.setSale(
//             tokenContract,
//             newTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: address(0),
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );

//         vm.stopPrank();
//     }

//     function test_MintingOnWrappedWithNoConfig() public {
//         uint256 aliceBalance = wisdomCurrency.balanceOf(alice);
//         uint256 bobBalance = wisdomCurrency.balanceOf(bob);
//         uint256 initialTreasureBalance = address(zoraFeesTreasury).balance;

//         vm.startPrank(alice);

//         bytes[] memory actions = new bytes[](0);

//         address _tokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );

//         IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);

//         uint256 newTokenId = tokenContract.setupNewToken("", 100);

//         tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         tokenContract.addPermission(1, address(wrapper), tokenContract.PERMISSION_BIT_MINTER());

//         // tokenContract.callSale(
//         //     newTokenId,
//         //     wrappedStrategy,
//         //     abi.encodeWithSelector(
//         //         ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//         //         newTokenId,
//         //         ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//         //             pricePerToken: 0.1 ether,
//         //             saleStart: 0,
//         //             saleEnd: type(uint64).max,
//         //             maxTokensPerAddress: 1,
//         //             fundsRecipient: address(0)
//         //         })
//         //     )
//         // );

//         wrapper.setSale(
//             tokenContract,
//             newTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );
//         vm.stopPrank();

//         vm.startPrank(bob);
//         deal(address(wisdomCurrency), bob, 1 ether);
//         deal(bob, 1 ether);
//         uint256 bobEthBalance = address(bob).balance;
//         wisdomCurrency.approve(address(wrappedStrategy), 1 ether);
//         vm.expectRevert(abi.encodeWithSignature("SaleEnded()"));
//         tokenContract.mint{value: ZORA_MINT_FEE}(wrappedStrategy, newTokenId, 1, abi.encode(bob));
//     }

//     function test_MintingOnWrapperWithNoConfig() public {
//         uint256 aliceBalance = wisdomCurrency.balanceOf(alice);
//         uint256 bobBalance = wisdomCurrency.balanceOf(bob);
//         uint256 initialTreasureBalance = address(zoraFeesTreasury).balance;

//         vm.startPrank(alice);

//         bytes[] memory actions = new bytes[](0);

//         address _tokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );

//         IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);

//         uint256 newTokenId = tokenContract.setupNewToken("", 100);

//         tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         tokenContract.addPermission(1, address(wrapper), tokenContract.PERMISSION_BIT_MINTER());

//         tokenContract.callSale(
//             newTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 newTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 0.1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 1,
//                     fundsRecipient: alice
//                 })
//             )
//         );

//         vm.stopPrank();

//         vm.startPrank(bob);
//         deal(address(wisdomCurrency), bob, 1 ether);
//         deal(bob, 1 ether);
//         uint256 bobEthBalance = address(bob).balance;
//         wisdomCurrency.approve(address(wrapper), 1 ether);
//         vm.expectRevert();
//         wrapper.mint(tokenContract, newTokenId, 1, bob);
//     }

//     function test_TwoContractsUsingSameStrat() public {
//         vm.startPrank(alice);
//         //A dynamic array of bytes named actions is created with a size of 0. This array is used to store actions, but in this case, it is initialized as an empty array.
//         bytes[] memory actions = new bytes[](0);
//         // The createContract function is called on the factory contract, which creates a new Zora collection. The function takes the following parameters:
//         // name: The name of the collection.
//         // symbol: The symbol of the collection.
//         // royalty: The royalty configuration of the collection.
//         // creator: The address of the creator of the collection.
//         // actions: The actions that are to be performed on the collection.
//         address _tokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );
//         // The address of the new collection (_tokenContract) is assigned to the variable tokenContract.
//         IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);
//         // set up a new token, setupNewToken takes two parameters:
//         // tokenURI: The URI of the token.
//         // supply: The supply of the token.
//         uint256 newTokenId = tokenContract.setupNewToken("", 100);

//         // give the wrappedStrategy and the wrapperStrategy the minter role
//         // this is the original Strategy from Zora
//         tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         // this is the new Strategy
//         tokenContract.addPermission(1, address(wrapper), tokenContract.PERMISSION_BIT_MINTER());

//         // call the wrapped strategy to set up the sale
//         tokenContract.callSale(
//             newTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 newTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 0,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );

//         // call the wrapper strategy to set up the sale
//         wrapper.setSale(
//             tokenContract,
//             newTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );

//         vm.stopPrank();

//         vm.startPrank(gav);
//         //A dynamic array of bytes named actions is created with a size of 0. This array is used to store actions, but in this case, it is initialized as an empty array.
//         bytes[] memory secondActions = new bytes[](0);
//         // The createContract function is called on the factory contract, which creates a new Zora collection. The function takes the following parameters:
//         // name: The name of the collection.
//         // symbol: The symbol of the collection.
//         // royalty: The royalty configuration of the collection.
//         // creator: The address of the creator of the collection.
//         // actions: The actions that are to be performed on the collection.
//         address _secondTokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), gav, secondActions
//         );
//         // The address of the new collection (_tokenContract) is assigned to the variable tokenContract.
//         IZoraCreator1155 secondTokenContract = IZoraCreator1155(_secondTokenContract);
//         // set up a new token, setupNewToken takes two parameters:
//         // tokenURI: The URI of the token.
//         // supply: The supply of the token.
//         uint256 secondNewTokenId = secondTokenContract.setupNewToken("", 100);

//         // give the wrappedStrategy and the wrapper the minter role
//         // this is the original Strategy from Zora
//         secondTokenContract.addPermission(1, address(wrappedStrategy), secondTokenContract.PERMISSION_BIT_MINTER());
//         // this is the new Strategy
//         secondTokenContract.addPermission(1, address(wrapper), secondTokenContract.PERMISSION_BIT_MINTER());

//         // call the wrapped strategy to set up the sale
//         secondTokenContract.callSale(
//             secondNewTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 secondNewTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 0,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );

//         // call the wrapper strategy to set up the sale
//         wrapper.setSale(
//             secondTokenContract,
//             secondNewTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );

//         vm.stopPrank();

//         vm.startPrank(bob);
//         deal(address(wisdomCurrency), bob, 2 ether);
//         deal(bob, 1 ether);

//         wisdomCurrency.approve(address(wrapper), 2 ether);

//         wrapper.mint(tokenContract, 1, 1, bob);
//         wrapper.mint(secondTokenContract, 1, 1, bob);

//         assertEq(wisdomCurrency.balanceOf(address(alice)), 2 ether);
//         assertEq(wisdomCurrency.balanceOf(address(bob)), 0 ether);
//         assertEq(tokenContract.balanceOf(bob, 1), 1);
//         assertEq(secondTokenContract.balanceOf(bob, 1), 1);
//     }

//     function test_WrapperMintFlowToAliceFromBob() public {
//         vm.startPrank(alice);
//         //A dynamic array of bytes named actions is created with a size of 0. This array is used to store actions, but in this case, it is initialized as an empty array.
//         bytes[] memory actions = new bytes[](0);
//         // The createContract function is called on the factory contract, which creates a new Zora collection. The function takes the following parameters:
//         // name: The name of the collection.
//         // symbol: The symbol of the collection.
//         // royalty: The royalty configuration of the collection.
//         // creator: The address of the creator of the collection.
//         // actions: The actions that are to be performed on the collection.
//         address _tokenContract = factory.createContract(
//             "test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions
//         );
//         // The address of the new collection (_tokenContract) is assigned to the variable tokenContract.
//         IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);
//         // set up a new token, setupNewToken takes two parameters:
//         // tokenURI: The URI of the token.
//         // supply: The supply of the token.
//         uint256 newTokenId = tokenContract.setupNewToken("", 100);

//         // give the wrappedStrategy and the wrapper the minter role
//         // this is the original Strategy from Zora
//         tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
//         // this is the wrapper - we need to give the wrapper the admin permmission
//         tokenContract.addPermission(1, address(wrapper), tokenContract.PERMISSION_BIT_ADMIN());

//         // call the wrapped strategy to set up the sale
//         tokenContract.callSale(
//             newTokenId,
//             wrappedStrategy,
//             abi.encodeWithSelector(
//                 ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
//                 newTokenId,
//                 ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
//                     pricePerToken: 1 ether,
//                     saleStart: 0,
//                     saleEnd: type(uint64).max,
//                     maxTokensPerAddress: 0,
//                     fundsRecipient: address(0)
//                 })
//             )
//         );

//         // call the wrapper strategy to set up the sale
//         wrapper.setSale(
//             tokenContract,
//             newTokenId,
//             ZoraCreator1155ERC20Wrapper.ERC20SalesConfig({
//                 wrappedStrategy: wrappedStrategy,
//                 maxTokensPerAddress: 100,
//                 fundsRecipient: alice,
//                 pricePerToken: 1 ether,
//                 currency: wisdomCurrency
//             })
//         );

//         vm.stopPrank();

//         vm.startPrank(bob);
//         deal(address(wisdomCurrency), bob, 1 ether);
//         deal(bob, 1 ether);

//         wisdomCurrency.approve(address(wrapper), 1 ether);

//         //    function mint(IZoraCreator1155 tokenContract, uint256 tokenId, uint256 quantity, address mintTo)

//         tokenContract.mint(wrapper, newTokenId, 1, alice);

//         assertEq(wisdomCurrency.balanceOf(address(alice)), 1 ether);
//         assertEq(wisdomCurrency.balanceOf(address(bob)), 0 ether);
//         assertEq(tokenContract.balanceOf(bob, 1), 1);
//     }
// }
