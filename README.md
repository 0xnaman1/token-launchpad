## Fundraising Token Launchpad [Bancor Bonding Curve]

### Verified contract deployments [Ethereum Sepolia]

```rust
// USDC deployed on Sepolia 
USDC: 0x80dbd48629244FddD14EE30F0570C5E427d31f91

// Launchpad smart contracts
Factory Proxy: 0x70EDbAe6B0445e08AeFd716D5644EA8Ddc30ceAB
Factory Implementation: 0x7e2b3f8ad748943c03374a069f835d9e42bc30e0

// One token launch deployed for testing (Minimal Clone)
Launch: 0xb21E343C9e537361685980a27D7c0436830ba279
```

### A Buy Transaction

[Etherscan link](https://sepolia.etherscan.io/tx/0xe39fa2324eb906195886b1bda63bbebe179fd22c3fcf7a9359807fc24fbd4f5f)

### Build

```shell
$ forge build
```

### Test

Forked tests on Ethereum Sepolia

```shell
$ forge test
```

### Thought process

The launchpad smart contract could follow one of 2 patterns

- Singleton Design
- Factory Pattern

The singleton pattern would consist of a single smart contract managing various token launches. This would be a UUPS upgradeable smart contract. This would be more economical since there would be a single deployment for the contract.

This repository follows a Factory Pattern approach. Each token launch is separate which is easier to manage and test individual contracts. The `Factory.sol` is a UUPS upgradeable smart contract which deploys minimal clones `Launch.sol` contract for each token launch. 

Minimal clone deployments are really economical for they are non upgradeable. For eg, during testing, a `Launch.sol` deployment only incurred $\$1.3$  transaction fees on sepolia testnet. A combination of UUPS proxy + minimal clones is used for its sake of modularity. 

The `Factory.sol` is upgradeable, so a new factory could be written with a new minimal clone implementation of `Launch.sol` as well. Factory pattern was chosen instead of Singleton cause managing state of various token launches in their own contracts is fairly simple as compared to managing the state of all token launches in a single smart contract, which could get bloated if there are too many token launches happening. 

### Logic

The fundraising follows the Bancor bonding curve. The price sensitivity of the curve depends upon the reserve ratio. Reserve ratio is intuitively calculated in the `Launch.sol` contract to ensure that the target funding would be achieved by selling 500M tokens. To calculate reserve ratio, the deployer must set the initial price of the token by adding some USDC liquidity to the deployed `Launch.sol` contract. Once the initial price is set, it can be used to determine the approx reserve ratio. 

$$ price = {amt(USDC) \over amt(Token)} $$

Using the initial price, the reserve ratio can be calculated as

$$ RR = {targetAmount(\$) \over tokenSupply * tokenPrice} $$

This sets the reserve ratio. The `BancorBondingCurve.sol` is used to calculate the minted tokens and the USDC return amount for each buy and sell respectively. 

Once the funding is achieved upon selling 500M tokens, the appropriate liquidity is added to UniswapV2 pool.
