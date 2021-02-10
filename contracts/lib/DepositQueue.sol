// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.8.2;
pragma experimental ABIEncoderV2;

import "../structs/Deposit.sol";

contract DepositQueue {
    mapping(uint256 => Deposit) queue;
    uint256 first = 1;
    uint256 last = 0;

    function enqueue(Deposit memory data) public {
        last += 1;
        queue[last] = data;
    }

    function dequeue() public returns (Deposit memory data) {
        require(last >= first);  // non-empty queue
        data = queue[first];
        delete queue[first];
        first += 1;
    }

    function isNotEmpty() view public returns(bool) {
        return last >= first;
    }
}