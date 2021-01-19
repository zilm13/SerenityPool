# SerenityPool
PoC (Proof of Concept) of Eth2 pool with shared validator ownership and control made to validate system contract design and requirements.
  
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
Various utils to make tests possible. Helpers for generation of fixtures. Run util tests with
```shell
cd util
npm test
```