<br/>
<p align="center">
<a href="" target="_blank">
<img src="logo.svg" width="200">
</a>
</p>
<br/>

## About
___
* `FennecSwap contract for P2P exchange between users.`
* `The basic principle of trust is based on the freezing of deposits of both participants in the transaction.`
* `This project uses chainlink price feed contracts to determine the price of ETH, BNB and MATIC.`
* `The possibility of stacking the token Fennec to make a profit from the contract FennecSwap.`
## Manual for build and tests
___

**Installing** (first of all install [foundry](https://book.getfoundry.sh/))

```bash
git clone https://github.com/FennecTechnology/FennecSwap && cd FennecSwap
```

```bash
forge install smartcontractkit/chainlink, OpenZeppelin/openzeppelin-contracts, foundry-rs/forge-std
```

```bash
forge build
```

**Running a local blockchain node (Anvil)**

```bash
anvil
```

**Testing contracts**
```bash
forge test
```