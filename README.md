# SerenityPool
PoC (Proof of Concept) of Eth2 pool with shared validator funding and control made to validate system contract design and requirements.

Users deposit any amount of money, which is fractional to the whole validator deposit, user funds are combined for a whole validator deposit, deposit is submitted and users are guaranteed to get a share of their investment after validator exit and withdrawal is initiated and processed. During the validator's active life user could split or sell his share, which is similar to bond without intermediate coupons but with guaranteed time of examination.

Validator should be run by service which shouldn't disclose validator private key but is guaranteed to get their fees on exit. It's questionable if there is a way to protect users' investments from validator slashing as whole validator work is done off-chain, though at least slashing insurance pool could be tried on.
  
---

Start development with 
```shell
npm install
```

### contracts/  
- **SerenityPool** - Main pool contract
- **WithdrawalContract** - Withdrawal target contract 
- **SystemContract** - Mock of withdrawal system contract which is going to be system contract on Eth1 handling withdrawals

### test/
Truffle tests for all contracts, run with
```shell
truffle test
```

### util/
Various utilities to make tests possible. Helpers for generation of fixtures. Run util tests with
```shell
cd util
npm test
```