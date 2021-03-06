// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.8.2;

import "../lib/FundDeque.sol";
import "../WithdrawalContract.sol";

struct Validator {
    bytes withdrawalCredentials;
    FundDeque shares;
    uint256 endOfLife;
    bytes voluntaryExit;
    bytes exitSignature;
    IWithdrawalContract withdrawalContract;
}