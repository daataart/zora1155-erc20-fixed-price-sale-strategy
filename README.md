# Zora1155 Fixed Price Strategy for ERC20s

**WARNING: as yet this contract is not fit for use, due to [this issue](https://github.com/ourzora/zora-1155-contracts/issues/126) - see below**

This repo contains an `IMinter1155` contract, which an be used as a sale strategy/minting control for a Zora Creator 1155 contract.

It allows for 1155 mints for a price denominated in any ERC20.

This strategy is intended to wrap an existing, deployed ZoraFixedPriceSaleStrategy. This is so the ERC20 strategy can inherit the start/end times from the wrapped strategy, which makes maintaining both strategies in parallel easier.

Caveats:
* The ERC20 strategy has its own `maxTokensPerAddress` value. e.g. if your ETH strategy has a max per address of 5 and your ERC20 strategy has a max per address of 5, some address could mint a total of 10. The overall supply of the token is respected regardless.
* You must set a funds recipient for each token. There's no way to withdraw an ERC20 from the 1155 contract as you can with ETH.

### Current major problem
Due to [this issue](https://github.com/ourzora/zora-1155-contracts/issues/126), there is no way for the strategy to know who the caller of the mint function is on the token contract. At the moment the price in the specified ERC20 is transferred from the _recipient of the token_. However, this causes a major issue if someone inadvertently approves a higher allowance than the exact price of their first mint. At that point, anyone who uses this strategy may create a drop with a price denominated in the same ERC20 and then mint to that recipient, capturing any excess ERC20 allowance for themselves.

For now, we might make this contract Ownable and restrict its use, then at least the trust relationship established with the owner holds for any other sales added to this strategy.

Alternatively, we could explore using the `adminMint` function on the IZoraCreator1155 interface, and wrapping the token contract instead of the strategy, bypassing the `mint` function altogether. This would allow the contract to transfer from the EAO/contract that is doing the minting, rather than the recipient of the token.

## Development

This project uses [Foundry](https://getfoundry.sh). See the [book](https://book.getfoundry.sh/getting-started/installation.html) for instructions on how to install and use Foundry.

The tests are intended to be run against a mainnet fork. So,

```bash
forge test --fork-url {insert a mainnet ethereum rpc url here}
```
