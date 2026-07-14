# Deploy your first token on ZCore

A tiny, **clone-and-run** example that deploys an **ERC-20 token** to the **ZCore Network** with
[Foundry](https://getfoundry.sh). No prior blockchain experience needed — follow the steps below and
you'll have a live token in a couple of minutes.

ZCore is a next-gen, EVM-compatible Layer 1 (Cancun) — everything you already know from Ethereum
tooling (Foundry, Hardhat, MetaMask, ethers) works as-is.

---

## Network details

| | |
|---|---|
| Network name | **ZCore** |
| Chain ID | **92673** |
| RPC URL | `https://testnet.zcore.network/rpc` |
| Currency symbol | **ZCR** |
| Block explorer | `https://testnet.zcore.network` |
| Faucet (free test ZCR) | `https://dashboard.zcore.network/faucet` |

---

## Prerequisites

1. **Foundry** — install it once:
   ```bash
   curl -L https://foundry.paradigm.xyz | bash && foundryup
   ```
2. **A wallet + its private key** (e.g. from MetaMask). You'll fund it with free test ZCR in Step 2.

---

## Step 1 — Get the code

```bash
git clone https://github.com/zcr-network/hello-zcore.git
cd hello-zcore
```

## Step 2 — Get free test ZCR (for gas)

Deploying costs a tiny amount of gas, paid in **ZCR**. Grab some for free:

1. Open the **faucet**: https://dashboard.zcore.network/faucet
2. Connect your wallet and click **Request 100 ZCR** — it arrives in seconds (no gas needed to claim).

> New wallet? The dashboard's **"+ Add Network"** button adds ZCore to MetaMask in one click.

## Step 3 — Set your private key

```bash
cp .env.example .env
# then edit .env and paste your wallet's private key:
# PRIVATE_KEY=0x....
```

> ⚠️ Use a **throwaway/testnet** key. Never commit `.env` or share a key that holds real funds.

## Step 4 — Deploy the token 🚀

The token's **name, symbol and supply** are the constructor arguments — change them to whatever you want.
This deploys a token called **"My ZCore Token" (MZT)** with a supply of **1,000,000**, all minted to you:

```bash
source .env
forge create src/MyToken.sol:MyToken \
  --rpc-url zcore \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --constructor-args "My ZCore Token" "MZT" 1000000000000000000000000
```

Foundry prints **`Deployed to: 0x....`** — that's your token's address. 🎉

> `1000000000000000000000000` = 1,000,000 tokens × 10^18 (ERC-20 uses 18 decimals).

## Step 5 — See it on the explorer

Open `https://testnet.zcore.network/address/<your-token-address>` — you'll see the contract, and your
wallet holding the full supply.

**Verify the source** (so anyone can read/trust the code) is optional but nice:

```bash
forge verify-contract <your-token-address> src/MyToken.sol:MyToken \
  --verifier blockscout \
  --verifier-url https://testnet.zcore.network/api/ \
  --constructor-args $(cast abi-encode "constructor(string,string,uint256)" "My ZCore Token" "MZT" 1000000000000000000000000)
```

## Step 6 — Add the token to your wallet

In MetaMask → **Import tokens** → paste your token address. Your 1,000,000 MZT show up, ready to send.

---

---

## Bonus: deploy an NFT (ERC-721) 🖼️

Same flow, a different contract — `src/MyNFT.sol` is a self-contained NFT collection. Deploy it with a
name, symbol and a metadata base URI (`tokenURI(id)` = baseURI + id):

```bash
source .env
forge create src/MyNFT.sol:MyNFT \
  --rpc-url zcore \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --constructor-args "My ZCore NFT" "MZN" "https://my-nft.example/metadata/"
```

Then **mint** your first NFT (only the deployer/owner can mint; token IDs start at 0):

```bash
cast send <your-nft-address> "mint(address)" <your-wallet-address> \
  --rpc-url zcore --private-key $PRIVATE_KEY
```

Check it on `https://testnet.zcore.network/token/<your-nft-address>` — you'll see the collection and
token #0 owned by your wallet. That's it — you just minted an NFT on ZCore. 🎉

---

## Alternative: scripted deploy

Prefer a repeatable Foundry script? Install forge-std, create `script/Deploy.s.sol`, and run it:

```bash
forge install foundry-rs/forge-std
```
```solidity
// script/Deploy.s.sol
// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;
import {Script, console2} from "forge-std/Script.sol";
import {MyToken} from "../src/MyToken.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast(vm.envUint("PRIVATE_KEY"));
        MyToken token = new MyToken("My ZCore Token", "MZT", 1_000_000 ether);
        vm.stopBroadcast();
        console2.log("MyToken deployed at:", address(token));
    }
}
```
```bash
source .env && forge script script/Deploy.s.sol:Deploy --rpc-url zcore --broadcast
```

## Alternative: OpenZeppelin (production)

`src/MyToken.sol` is intentionally dependency-free so it "just works". For real projects, use the
audited [OpenZeppelin ERC20](https://docs.openzeppelin.com/contracts/erc20):

```bash
forge install OpenZeppelin/openzeppelin-contracts
```
```solidity
import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
contract MyToken is ERC20 {
    constructor(uint256 supply) ERC20("My ZCore Token", "MZT") { _mint(msg.sender, supply); }
}
```

---

## Links

- Dashboard (swap, bridge, faucet, validators): https://dashboard.zcore.network
- Explorer: https://testnet.zcore.network
- Run a validator: https://github.com/zcr-network/validator

Built something? Share it. Welcome to ZCore. 🟢
