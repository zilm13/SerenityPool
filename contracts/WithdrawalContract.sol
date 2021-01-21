// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.7.0;
pragma experimental ABIEncoderV2;

// Withdrawal receiver contract
interface IWithdrawalContract {
    event Received(address _sender, uint _value);
    function withdraw() external;
    function getAddress() external view returns (address);
}

contract WithdrawalContract is IWithdrawalContract {
    address payable public owner;

    modifier onlyOwner() {
        if (msg.sender == owner) _;
    }

    constructor() public {
        owner = msg.sender;
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