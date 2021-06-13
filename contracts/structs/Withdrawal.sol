// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.8.2;

struct Withdrawal {
    uint64 validator_index;
    bytes32 withdrawal_credentials;
    uint64 withdrawn_epoch;
    uint64 amount;
}