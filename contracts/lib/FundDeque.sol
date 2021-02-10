// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.8.2;
pragma experimental ABIEncoderV2;

import "../structs/Fund.sol";

contract FundDeque {
    mapping(uint256 => Fund) deque;
    uint256 first = 2**255;
    uint256 last = first - 1;

    function pushLeft(Fund memory data) public {
        first -= 1;
        deque[first] = data;
    }

    function pushRight(Fund memory data) public {
        last += 1;
        deque[last] = data;
    }

    function popLeft() public returns (Fund memory data) {
        require(last >= first);  // non-empty deque
        data = deque[first];
        delete deque[first];
        first += 1;
    }

    function popRight() public returns (Fund memory data) {
        require(last >= first);  // non-empty deque
        data = deque[last];
        delete deque[last];
        last -= 1;
    }
}