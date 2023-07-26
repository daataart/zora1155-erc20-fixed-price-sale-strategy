// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Test, Vm} from "forge-std/Test.sol";
import "src/ERC20FixedPriceSaleStrategy.sol";
import "zora-1155-contracts/interfaces/IZoraCreator1155Factory.sol";
import "zora-1155-contracts/interfaces/IZoraCreator1155.sol";
import { ZoraCreatorFixedPriceSaleStrategy } from "zora-1155-contracts/minters/fixed-price/ZoraCreatorFixedPriceSaleStrategy.sol";
import {ILimitedMintPerAddress} from "zora-1155-contracts/interfaces/ILimitedMintPerAddress.sol";

import "zora-1155-contracts/interfaces/ICreatorRoyaltiesControl.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/StdUtils.sol";

// factory: This is a constant variable that is assigned the address where the IZoraCreator1155Factory contract is deployed.
IZoraCreator1155Factory constant factory = IZoraCreator1155Factory(0xA6C5f2DE915240270DaC655152C3f6A91748cb85);
// wrappedStrategy: This is a constant variable that is assigned the address where the ZoraCreatorFixedPriceSaleStrategy contract is deployed.
ZoraCreatorFixedPriceSaleStrategy constant wrappedStrategy = ZoraCreatorFixedPriceSaleStrategy(0x5Ff5a77dD2214d863aCA809C0168941052d9b180);
// wisdomCurrency: This is a constant variable that is assigned the address where the wisdomCurrency ERC20 token contract is deployed.
// by defining this as an IERC20, we can call the ERC20 functions on this contract.
IERC20 constant wisdomCurrency = IERC20(0xF6b0Dc792B80a781C872B2f0B7787BfE72546B6F);
IERC20 constant usdc = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);

contract TestERC20FixedPriceSaleStrategy is Test {
    
    // Define a variable to hold the wrapper strategy
    ERC20FixedPriceSaleStrategy wrapperStrategy;
    // Define an address for testing
    address payable alice;
    address payable bob;

    function setUp() public {
        // Create a new instance of the wrapper strategy, at the moment of setup, it is identical to the wrapped strategy (Zora Create Fixed Price Sale Strategy)
        wrapperStrategy = new ERC20FixedPriceSaleStrategy(wrappedStrategy);
        // Make mock addresses for the tests
        alice = payable(makeAddr("alice"));
        bob = payable(makeAddr("bob"));
    }

    function test_MintFlow() public {

        vm.startPrank(alice);
         //A dynamic array of bytes named actions is created with a size of 0. This array is used to store actions, but in this case, it is initialized as an empty array.
        bytes[] memory actions = new bytes[](0);
        // The createContract function is called on the factory contract, which creates a new Zora collection. The function takes the following parameters:
        // name: The name of the collection.
        // symbol: The symbol of the collection.
        // royalty: The royalty configuration of the collection.
        // creator: The address of the creator of the collection.
        // actions: The actions that are to be performed on the collection.
        address _tokenContract = factory.createContract("test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions);
        // The address of the new collection (_tokenContract) is assigned to the variable tokenContract.
        IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);
        // set up a new token, setupNewToken takes two parameters:
        // tokenURI: The URI of the token.
        // supply: The supply of the token.
        uint256 newTokenId = tokenContract.setupNewToken("", 100);

        // give the wrappedStrategy and the wrapperStrategy the minter role
        // this is the original Strategy from Zora
        tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
        // this is the new Strategy
        tokenContract.addPermission(1, address(wrapperStrategy), tokenContract.PERMISSION_BIT_MINTER());

        // set up the sale on the wrapped strategy, this is done via the token contract
        ZoraCreatorFixedPriceSaleStrategy.SalesConfig memory salesConfig = ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
            saleStart: 0,
            saleEnd: 1790219309,
            maxTokensPerAddress: 100,
            pricePerToken: 0.5 ether,
            fundsRecipient: address(0)
        });

        // call the wrapped strategy to set up the sale
        tokenContract.callSale(
            newTokenId,
            wrappedStrategy,
            abi.encodeWithSelector(
                ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
                newTokenId,
                ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
                    pricePerToken: 1 ether,
                    saleStart: 0,
                    saleEnd: type(uint64).max,
                    maxTokensPerAddress: 0,
                    fundsRecipient: address(0)
                })
            )
        );

        ERC20FixedPriceSaleStrategy.ERC20SalesConfig memory erc20salesconfig = ERC20FixedPriceSaleStrategy.ERC20SalesConfig({
            maxTokensPerAddress: 100,
            fundsRecipient: alice,
            price: 1 ether,
            currency: wisdomCurrency
        });

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = newTokenId;
        ERC20FixedPriceSaleStrategy.ERC20SalesConfig[] memory salesConfigs = new ERC20FixedPriceSaleStrategy.ERC20SalesConfig[](1);
        salesConfigs[0] = erc20salesconfig;
        
        // call the wrapper strategy to set up the sale
        tokenContract.callSale(
            newTokenId,
            wrapperStrategy,
            abi.encodeWithSelector(
                ERC20FixedPriceSaleStrategy.setSales.selector,
                tokenIds,
                salesConfigs
            )
        );

        vm.stopPrank();
        
        vm.startPrank(bob);
        deal(address(wisdomCurrency), bob, 1 ether);
        deal(bob, 1 ether);

        wisdomCurrency.approve(address(wrapperStrategy), 1 ether);
        // bob mints from the tokenContract
        // the mint function takes the following parameters:
        // to: The address of the recipient of the token.
        // tokenId: The ID of the token.
        // amount: The amount of tokens to mint.
        // data: The data to be passed to the token contract.

        tokenContract.mint{value: 0.1 ether}(wrapperStrategy, 1, 1, abi.encode(bob));   

        assertEq(wisdomCurrency.balanceOf(address(alice)), 1 ether);
        assertEq(wisdomCurrency.balanceOf(address(bob)), 0 ether);
        assertEq(tokenContract.balanceOf(bob, 1), 1);
    }

    function test_SaleStart() external {
        // create a new zora collection from the factory
        
        vm.startPrank(alice);
        bytes[] memory actions = new bytes[](0);
        address _tokenContract = factory.createContract("test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions);
        IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);
        // set up a new token
        uint256 newTokenId = tokenContract.setupNewToken("", 100);

        // give the wrappedStrategy and the wrapperStrategy the minter role
        // this is the original Strategy from Zora
        tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
        // this is the new Strategy
        tokenContract.addPermission(1, address(wrapperStrategy), tokenContract.PERMISSION_BIT_MINTER());

        // set up the sale on the wrapped strategy, this is done via the token contract
        // 
        ZoraCreatorFixedPriceSaleStrategy.SalesConfig memory salesConfig = ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
            saleStart: uint64(block.timestamp + 1 days),
            saleEnd: 1790219309,
            maxTokensPerAddress: 100,
            pricePerToken: 0.5 ether,
            fundsRecipient: address(0)
        });

        // call the wrapped strategy to set up the sale
        tokenContract.callSale(
            newTokenId,
            wrappedStrategy,
            abi.encodeWithSelector(
                ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
                newTokenId,
                ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
                    pricePerToken: 1 ether,
                    saleStart: uint64(block.timestamp + 1 days),
                    saleEnd: type(uint64).max,
                    maxTokensPerAddress: 0,
                    fundsRecipient: address(0)
                })
            )
        );

        ERC20FixedPriceSaleStrategy.ERC20SalesConfig memory erc20salesconfig = ERC20FixedPriceSaleStrategy.ERC20SalesConfig({
            maxTokensPerAddress: 100,
            fundsRecipient: alice,
            price: 1 ether,
            currency: wisdomCurrency
        });

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = newTokenId;
        ERC20FixedPriceSaleStrategy.ERC20SalesConfig[] memory salesConfigs = new ERC20FixedPriceSaleStrategy.ERC20SalesConfig[](1);
        salesConfigs[0] = erc20salesconfig;
        
        // call the wrapper strategy to set up the sale
        tokenContract.callSale(
            newTokenId,
            wrapperStrategy,
            abi.encodeWithSelector(
                ERC20FixedPriceSaleStrategy.setSales.selector,
                tokenIds,
                salesConfigs
            )
        );

        vm.stopPrank();

        vm.deal(bob, 20 ether);

        vm.expectRevert(abi.encodeWithSignature("SaleHasNotStarted()"));
        vm.prank(bob);
        tokenContract.mint{value: 10 ether}(wrapperStrategy, newTokenId, 10, abi.encode(bob));
    }


    function test_SaleEnd() external {

        address payable alice = payable(address(0x999));
      

        // create a new zora collection from the factory
        
        vm.startPrank(alice);
        bytes[] memory actions = new bytes[](0);
        address _tokenContract = factory.createContract("test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions);
        IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);
        // set up a new token
        uint256 newTokenId = tokenContract.setupNewToken("", 100);

        // give the wrappedStrategy and the wrapperStrategy the minter role
        // this is the original Strategy from Zora
        tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
        // this is the new Strategy
        tokenContract.addPermission(1, address(wrapperStrategy), tokenContract.PERMISSION_BIT_MINTER());

        // set up the sale on the wrapped strategy, this is done via the token contract
        // 
        ZoraCreatorFixedPriceSaleStrategy.SalesConfig memory salesConfig = ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
            saleStart: 0,
            saleEnd: 1790219309,
            maxTokensPerAddress: 100,
            pricePerToken: 0.5 ether,
            fundsRecipient: address(0)
        });

        // call the wrapped strategy to set up the sale
        tokenContract.callSale(
            newTokenId,
            wrappedStrategy,
            abi.encodeWithSelector(
                ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
                newTokenId,
                ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
                    pricePerToken: 1 ether,
                    saleStart: 0,
                    saleEnd: uint64(1 days),
                    maxTokensPerAddress: 0,
                    fundsRecipient: address(0)
                })
            )
        );

        ERC20FixedPriceSaleStrategy.ERC20SalesConfig memory erc20salesconfig = ERC20FixedPriceSaleStrategy.ERC20SalesConfig({
            maxTokensPerAddress: 100,
            fundsRecipient: alice,
            price: 1 ether,
            currency: wisdomCurrency
        });

        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = newTokenId;
        ERC20FixedPriceSaleStrategy.ERC20SalesConfig[] memory salesConfigs = new ERC20FixedPriceSaleStrategy.ERC20SalesConfig[](1);
        salesConfigs[0] = erc20salesconfig;
  
        // call the wrapper strategy to set up the sale
        tokenContract.callSale(
            newTokenId,
            wrapperStrategy,
            abi.encodeWithSelector(
                ERC20FixedPriceSaleStrategy.setSales.selector,
                tokenIds,
                salesConfigs
            )
        );

        vm.stopPrank();


        address bob = address(322);
        vm.deal(bob, 20 ether);
        vm.expectRevert(abi.encodeWithSignature("SaleEnded()"));
        vm.prank(bob);
        tokenContract.mint{value: 10 ether}(wrapperStrategy, newTokenId, 10, abi.encode(bob));

    }

    function test_MaxTokensPerAddress() external {
    
        address payable alice = payable(address(0x999));
        // create a new zora collection from the factory
        
        vm.startPrank(alice);
        bytes[] memory actions = new bytes[](0);
        address _tokenContract = factory.createContract("test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions);
        IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);
        // set up a new token
        uint256 newTokenId = tokenContract.setupNewToken("", 100);

        // give the wrappedStrategy and the wrapperStrategy the minter role
        // this is the original Strategy from Zora
        tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
        // this is the new Strategy
        tokenContract.addPermission(1, address(wrapperStrategy), tokenContract.PERMISSION_BIT_MINTER());

        // set up the sale on the wrapped strategy, this is done via the token contract
        // 
        ZoraCreatorFixedPriceSaleStrategy.SalesConfig memory salesConfig = ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
            saleStart: 0,
            saleEnd: 1790219309,
            maxTokensPerAddress: 1,
            pricePerToken: 0.5 ether,
            fundsRecipient: address(0)
        });

        // call the wrapped strategy to set up the sale
        tokenContract.callSale(
            newTokenId,
            wrappedStrategy,
            abi.encodeWithSelector(
                ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
                newTokenId,
                ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
                    pricePerToken: 1 ether,
                    saleStart: 0,
                    saleEnd: uint64(1 days),
                    maxTokensPerAddress: 1,
                    fundsRecipient: address(0)
                })
            )
        );

        ERC20FixedPriceSaleStrategy.ERC20SalesConfig memory erc20salesconfig = ERC20FixedPriceSaleStrategy.ERC20SalesConfig({
            maxTokensPerAddress: 1,
            fundsRecipient: alice,
            price: 1 ether,
            currency: wisdomCurrency
        });
        
        uint256[] memory tokenIds = new uint256[](1);
        tokenIds[0] = newTokenId;
        ERC20FixedPriceSaleStrategy.ERC20SalesConfig[] memory salesConfigs = new ERC20FixedPriceSaleStrategy.ERC20SalesConfig[](1);
        salesConfigs[0] = erc20salesconfig;
        
        // call the wrapper strategy to set up the sale
        tokenContract.callSale(
            newTokenId,
            wrapperStrategy,
            abi.encodeWithSelector(
                ERC20FixedPriceSaleStrategy.setSales.selector,
                tokenIds,
                salesConfigs
            )
        );

        vm.stopPrank();

        vm.warp(0.5 days);

        address bob = address(322);
        vm.deal(bob, 20 ether);
        deal(address(wisdomCurrency), bob, 1 ether);

        wisdomCurrency.approve(address(wrapperStrategy), 1 ether);

        vm.prank(bob);

        vm.expectRevert(abi.encodeWithSelector(ILimitedMintPerAddress.UserExceedsMintLimit.selector, bob, 1, 6));

         // bob mints from the tokenContract
        // the mint function takes the following parameters:
        //value: The amount of ether to send with the transaction.
        // to: The address of the recipient of the token.
        // tokenId: The ID of the token.
        // amount: The amount of tokens to mint.
        // data: The data to be passed to the token contract.
        tokenContract.mint{value: 6 ether}(wrapperStrategy, newTokenId, 6, abi.encode(bob));
    }

    function test_SaleForDifferentERC20s() external {
        uint256 initialWisdomBalance = wisdomCurrency.balanceOf(alice);
        uint256 initialUsdcBalance = usdc.balanceOf(alice);
        vm.startPrank(alice);
        bytes[] memory actions = new bytes[](0);
        address _tokenContract = factory.createContract("test", "test", ICreatorRoyaltiesControl.RoyaltyConfiguration(0, 0, address(0)), alice, actions);
        IZoraCreator1155 tokenContract = IZoraCreator1155(_tokenContract);
        uint256 FirstTokenId = tokenContract.setupNewToken("", 100);
        uint256 SecondTokenId = tokenContract.setupNewToken("", 100);
        tokenContract.addPermission(1, address(wrappedStrategy), tokenContract.PERMISSION_BIT_MINTER());
        tokenContract.addPermission(1, address(wrapperStrategy), tokenContract.PERMISSION_BIT_MINTER());

        ZoraCreatorFixedPriceSaleStrategy.SalesConfig memory salesConfig = ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
            saleStart: 0,
            saleEnd: type(uint64).max,
            maxTokensPerAddress: 100,
            pricePerToken: 1 ether,
            fundsRecipient: address(0)
        });

        tokenContract.callSale(
            FirstTokenId,
            wrappedStrategy,
            abi.encodeWithSelector(
                ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
                FirstTokenId,
                ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
                    pricePerToken: 1 ether,
                    saleStart: 0,
                    saleEnd: uint64(1 days),
                    maxTokensPerAddress: 1,
                    fundsRecipient: address(0)
                })
            )
        );

        tokenContract.callSale(
            SecondTokenId,
            wrappedStrategy,
            abi.encodeWithSelector(
                ZoraCreatorFixedPriceSaleStrategy.setSale.selector,
                SecondTokenId,
                ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
                    pricePerToken: 1 ether,
                    saleStart: 0,
                    saleEnd: uint64(1 days),
                    maxTokensPerAddress: 1,
                    fundsRecipient: address(0)
                })
            )
        );

        ERC20FixedPriceSaleStrategy.ERC20SalesConfig memory wisdomCurrencySalesConfig = ERC20FixedPriceSaleStrategy.ERC20SalesConfig({
            maxTokensPerAddress: 1,
            fundsRecipient: alice,
            price: 1 ether,
            currency: wisdomCurrency
        });

         ERC20FixedPriceSaleStrategy.ERC20SalesConfig memory usdcSalesConfig = ERC20FixedPriceSaleStrategy.ERC20SalesConfig({
            maxTokensPerAddress: 1,
            fundsRecipient: alice,
            price: 1 ether,
            currency: wisdomCurrency
        });

        uint256[] memory firstTokenIds = new uint256[](1);
        uint256[] memory secondTokenIds = new uint256[](1);
        firstTokenIds[0] = FirstTokenId;
        secondTokenIds[0] = SecondTokenId;
        ERC20FixedPriceSaleStrategy.ERC20SalesConfig[] memory wisdomSalesConfigs = new ERC20FixedPriceSaleStrategy.ERC20SalesConfig[](1);
        ERC20FixedPriceSaleStrategy.ERC20SalesConfig[] memory usdcSalesConfigs = new ERC20FixedPriceSaleStrategy.ERC20SalesConfig[](1);
        wisdomSalesConfigs[0] = wisdomCurrencySalesConfig;
        usdcSalesConfigs[0] = usdcSalesConfig;

        tokenContract.callSale(
            FirstTokenId,
            wrapperStrategy,
            abi.encodeWithSelector(
                ERC20FixedPriceSaleStrategy.setSales.selector,
                firstTokenIds,
               wisdomSalesConfigs
            )
        );

        tokenContract.callSale(
            FirstTokenId,
            wrapperStrategy,
            abi.encodeWithSelector(
                ERC20FixedPriceSaleStrategy.setSales.selector,
                secondTokenIds,
                usdcSalesConfigs
            )
        );


        vm.stopPrank();

        address bob = address(322);
        vm.deal(bob, 20 ether);
        deal(address(wisdomCurrency), bob, 1 ether);
        deal(address(usdc), bob, 1 ether);

        // Test here that the transaction fails if not approved?
        wisdomCurrency.approve(address(wrapperStrategy), 1 ether);
        usdc.approve(address(wrapperStrategy), 1 ether);

        vm.prank(bob);



        uint256 updatedWisdomBalance = wisdomCurrency.balanceOf(alice);
        uint256 updatedUsdcBalance = usdc.balanceOf(alice);

        // the mint function takes the following parameters:
        // to: The address of the recipient of the token.
        // tokenId: The ID of the token.
        // amount: The amount of tokens to mint.
        // data: The data to be passed to the token contract.

        tokenContract.mint{value: 1 ether}(wrapperStrategy, 1, 1, abi.encode(bob));   
        tokenContract.mint{value: 1 ether}(wrapperStrategy, 2, 1, abi.encode(bob));   



        assertEq(updatedWisdomBalance, 1 ether, "Incorrect fundsRecipient balance");
        assertEq(updatedUsdcBalance, 1 ether, "Incorrect fundsRecipient balance");
        // Test that bob's balance is reduced by token price multiplied by number minted
        // Test that alice's balance is increased by token price multiplied by number minted
    }

}
