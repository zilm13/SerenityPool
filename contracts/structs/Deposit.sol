// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.7.0;

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