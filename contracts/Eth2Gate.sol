// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.8.2;
pragma experimental ABIEncoderV2;

// Mock of Eth2 envelope send contract. Could be 3rd party service or system contract.
// Also the same could be done off-chain
interface IEth2Gate {
    event VoluntaryExit(bytes _voluntaryExit, bytes _signature);
    function sendSignedVoluntaryExit(
        bytes calldata _voluntaryExit,
        bytes calldata _signature,
        address _callbackAddress,
        bytes calldata _callData
    ) external;
    function pingBack(uint id) external;
}

contract Eth2Gate is IEth2Gate {
    struct Request {
        address callbackAddress;
        bytes callData;
    }
    address payable public owner;
    uint private counter = 0;
    mapping(uint => Request) requests;

    modifier onlyOwner() {
        if (msg.sender == owner) _;
    }

    constructor() {
        owner = payable(msg.sender);
    }

    // TODO: accept fee + callback gas, no callback functions
    function sendSignedVoluntaryExit(
        bytes calldata _voluntaryExit,
        bytes calldata _signature,
        address _callbackAddress,
        bytes calldata _callData
    )
    override
    public
    {
        requests[counter] =  Request({
        callbackAddress : _callbackAddress,
        callData: _callData
        });
        counter += 1;
        emit VoluntaryExit(_voluntaryExit, _signature);
    }

    function pingBack(uint id) override public onlyOwner {
        Request memory request = requests[id];
        delete requests[id];
        // TODO: spend no more gas than provided
        (bool success,) = request.callbackAddress.call(request.callData);
        require(success);
    }
}