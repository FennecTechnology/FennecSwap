<br/>
<p align="center">
<img src="About.svg" width="800">
</p>
<br/>

## Manual for build and tests
___

First of all install [foundry](https://book.getfoundry.sh/)

**Clone this repository**
```bash
git clone https://github.com/FennecTechnology/FennecSwap.git
```
```bash
cd FennecSwap
```

**Installing libraries**
```bash
forge install smartcontractkit/chainlink --no-git
```
```bash
forge install OpenZeppelin/openzeppelin-contracts --no-git
```
```bash
forge install foundry-rs/forge-std --no-git
```

**Build the project's smart contracts**
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