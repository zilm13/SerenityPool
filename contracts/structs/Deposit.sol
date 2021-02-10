// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.8.2;

import "../WithdrawalContract.sol";

struct Deposit {
    bytes pubKey;
    bytes withdrawalCredentials;
    bytes signature;
    bytes32 depositDataRoot;
    bytes voluntaryExit;
    bytes exitSignature;
    IWithdrawalContract withdrawalContract;
}