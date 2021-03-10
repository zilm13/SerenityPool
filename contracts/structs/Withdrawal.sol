// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.8.2;

struct Withdrawal {
    bytes32 pubkeyHash;
    bytes4 withdrawalTarget;
    bytes32 withdrawalCredentials;
    uint64 amount;
    uint64 epoch;
}