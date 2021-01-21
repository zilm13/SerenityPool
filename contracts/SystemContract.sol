// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.7.0;
pragma experimental ABIEncoderV2;

// Mock of withdrawals system contract
interface ISystemContract {
    function withdraw(bytes calldata _pubKey) external;
}

// TODO
contract SystemContract is ISystemContract {
    function withdraw(bytes calldata _pubKey) override public {}
}