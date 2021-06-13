// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.8.2;
pragma experimental ABIEncoderV2;

import "../structs/Withdrawal.sol";

contract WithdrawalUtil {
    // Compute withdrawal root (`Withdrawal` hash tree root)
    function _computeWithdrawalRoot(Withdrawal memory _withdrawal) public view returns (bytes32) {
        bytes32 two_root = sha256(abi.encodePacked(
                _toLittleEndian64(_withdrawal.validator_index),
                bytes24(0),
                _withdrawal.withdrawal_credentials
            ));
        bytes32 three_root = sha256(abi.encodePacked(
                _toLittleEndian64(_withdrawal.withdrawn_epoch),
                bytes24(0),
                _toLittleEndian64(_withdrawal.amount),
                bytes24(0)
            ));
        bytes32 node = sha256(abi.encodePacked(two_root, three_root));
        return node;
    }

    function _toLittleEndian64(uint64 _value) internal pure returns (bytes memory ret) {
        ret = new bytes(8);
        bytes8 bytesValue = bytes8(_value);
        // Byteswapping during copying to bytes.
        ret[0] = bytesValue[7];
        ret[1] = bytesValue[6];
        ret[2] = bytesValue[5];
        ret[3] = bytesValue[4];
        ret[4] = bytesValue[3];
        ret[5] = bytesValue[2];
        ret[6] = bytesValue[1];
        ret[7] = bytesValue[0];
    }
}