// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.13;

import "forge-std/Test.sol";
import "src/ERC20FixedPriceStrategy.sol";
import "zora-1155-contracts/interfaces/IZoraCreator1155Factory.sol";
import "zora-1155-contracts/interfaces/IZoraCreator1155.sol";
import { ZoraCreatorFixedPriceSaleStrategy } from "zora-1155-contracts/minters/fixed-price/ZoraCreatorFixedPriceSaleStrategy.sol";
import { RoyaltyConfiguration } from "zora-1155-contracts/interfaces/ICreatorRoyaltiesControl.sol";

IZoraCreator1155Factory constant factory = IZoraCreator1155Factory(0x0000000);
ZoraCreatorFixedPriceSaleStrategy constant wrappedStrategy = ZoraCreatorFixedPriceSaleStrategy("0x0000000");

contract TestERC20FixedPriceStrategy is Test {
    ERC20FixedPriceStrategy wrapperStrategy;
    address alice;

    function setUp() public {
        wrapperStrategy = new ERC20FixedPriceStrategy(wrappedStrategy);
        alice = makeAddr("alice");
    }

    function testBar() public {
        // create a new zora collection from the factory
        vm.startPrank(alice);
        defaultRoyaltyConfiguration = new RoyaltyConfiguration({
            royaltyMintSchedule: 100000,
            royaltyBPS: 0,
            royaltyRecipient: alice
        });
        IZoraCreator1155 tokenContract = factory.createContract("test", "test", defaultRoyaltyConfiguration, alice, []);

        // set up a new token
        tokenContract.setupNewToken("", 100);

        // give the wrappedStrategy and the wrapperStrategy the minter role
        tokenContract.addPermission(1, wrappedStrategy, ZoraCreator1155Impl.PERMISSION_BIT_MINTER);
        tokenContract.addPermission(1, wrapperStrategy, ZoraCreator1155Impl.PERMISSION_BIT_MINTER);

        // set up the sale on the wrapped strategy, this is done via the token contract
        ZoraCreatorFixedPriceSaleStrategy.SalesConfig memory salesConfig = ZoraCreatorFixedPriceSaleStrategy.SalesConfig({
            saleStart: 0,
            saleEnd: 1e20,
            maxTokensPerAddress: 100,
            pricePerToken: 0.5 ether,
            fundsRecipient: address(0)
        });

        tokenContract.callSale(1, wrappedStrategy, abi.encodeWithSelector(wrappedStrategy.setSales.selector, salesConfig));

    }
}
