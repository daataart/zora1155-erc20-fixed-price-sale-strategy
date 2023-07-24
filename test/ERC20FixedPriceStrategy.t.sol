// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import {Test, Vm} from "forge-std/Test.sol";
import "src/ERC20FixedPriceSaleStrategy.sol";
import "zora-1155-contracts/interfaces/IZoraCreator1155Factory.sol";
import "zora-1155-contracts/interfaces/IZoraCreator1155.sol";
import { ZoraCreatorFixedPriceSaleStrategy } from "zora-1155-contracts/minters/fixed-price/ZoraCreatorFixedPriceSaleStrategy.sol";
import "zora-1155-contracts/interfaces/ICreatorRoyaltiesControl.sol";
import "openzeppelin-contracts/contracts/token/ERC20/IERC20.sol";
import "forge-std/StdUtils.sol";

IZoraCreator1155Factory constant factory = IZoraCreator1155Factory(0xA6C5f2DE915240270DaC655152C3f6A91748cb85);
ZoraCreatorFixedPriceSaleStrategy constant wrappedStrategy = ZoraCreatorFixedPriceSaleStrategy(0x5Ff5a77dD2214d863aCA809C0168941052d9b180);
IERC20 constant wisdomCurrency = IERC20(0xF6b0Dc792B80a781C872B2f0B7787BfE72546B6F);

contract TestERC20FixedPriceSaleStrategy is Test {
    ERC20FixedPriceSaleStrategy wrapperStrategy;
    // Define an address for testing
    // address alice;
    // address bob;

    function setUp() public {
        wrapperStrategy = new ERC20FixedPriceSaleStrategy(wrappedStrategy);
        // Make mock addresses for the tests
        // alice = makeAddr("alice");
        // alice = makeAddr("bob");
    }

    function testBar() public {

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
        
        address bob = address(0x888);

        vm.startPrank(bob);
        deal(address(wisdomCurrency), bob, 1 ether);
        deal(bob, 1 ether);

        wisdomCurrency.approve(address(wrapperStrategy), 1 ether);

        tokenContract.mint{value: 0.1 ether}(wrapperStrategy, 1, 1, abi.encode(bob));   

        assertEq(wisdomCurrency.balanceOf(address(alice)), 1 ether);
        assertEq(wisdomCurrency.balanceOf(address(bob)), 0 ether);
        assertEq(tokenContract.balanceOf(bob, 1), 1);
    }
}
