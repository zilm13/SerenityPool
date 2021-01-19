// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.7.0;

import "../WithdrawalContract.sol";

struct Deposit {
    bytes pubkey;
    bytes withdrawal_credentials;
    bytes signature;
    bytes32 deposit_data_root;
    IWithdrawalContract withdrawalContract;
}