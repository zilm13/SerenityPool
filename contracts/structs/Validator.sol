// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.7.0;

import "../lib/FundDeque.sol";
import "../WithdrawalContract.sol";

struct Validator {
    bytes withdrawal_credentials;
    FundDeque shares;
    uint256 end_of_life;
    IWithdrawalContract withdrawalContract;
}