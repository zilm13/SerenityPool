// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.7.0;
pragma experimental ABIEncoderV2;

// Withdrawal receiver contract
interface IWithdrawalContract {
    event Received(address, uint);
    function withdraw() external;
    function getAddress() external view returns (address);
}

contract WithdrawalContract is IWithdrawalContract {
    address payable public owner;

    constructor() public {
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == owner) _;
    }

    receive() external payable {
        emit Received(msg.sender, msg.value);
    }

    function withdraw() override public onlyOwner {
        owner.transfer(address(this).balance);
    }

    function getAddress() override view public returns (address) {
        return address(this);
    }
}