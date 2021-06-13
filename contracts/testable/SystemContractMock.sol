// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.8.2;

import "./../SystemContract.sol";
import "./../structs/Withdrawal.sol";
import "./../lib/WithdrawalUtil.sol";

pragma experimental ABIEncoderV2;
pragma experimental ETH2OpCodes;

contract SystemContractMock is ISystemContract {
    WithdrawalUtil withdrawalUtil;
    mapping(bytes32 => bool) cashed;
    uint constant GWEI = 10 ** 9; // Gwei to wei multiplier

    constructor() {
        withdrawalUtil = new WithdrawalUtil();
    }

    // Mock withdrawal, doesn't verify any inputs, pays _withdrawal.amount to withdrawalCredentials address
    // Records withdrawal to avoid double withdrawal
    function withdraw(uint _slot, bytes32[] calldata _proof, uint64 _gIndex, Withdrawal calldata _withdrawal) override public {
        bytes32 node = withdrawalUtil._computeWithdrawalRoot(_withdrawal);
        require(!cashed[node]); // TODO: test me
        address target = _toAddress(abi.encodePacked(_withdrawal.withdrawal_credentials), 12);
        cashed[node] = true;
        address payable targetPayable = payable(target);
        targetPayable.transfer(_withdrawal.amount * GWEI);
    }

    function deposit() payable override public {
    }

    // Converts bytes to address
    // Copied from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
    function _toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }
}