// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.8.2;

import "./structs/Withdrawal.sol";
import "./lib/WithdrawalUtil.sol";

pragma experimental ABIEncoderV2;
pragma experimental ETH2OpCodes;

// Prototype of withdrawals system contract
interface ISystemContract {
    function withdraw(uint slot, bytes32[] calldata proof, uint64 gIndex, Withdrawal calldata withdrawal) external;
    function deposit() payable external;
}

contract SystemContract is ISystemContract {
    mapping(bytes32 => bool) cashed;
    uint64 constant WITHDRAWAL_GINDEX = 374;
    bytes4 constant ETH1_WITHDRAWAL_ADDRESS_PREFIX = 0x01000000;
    uint constant GWEI = 10 ** 9; // Gwei to wei multiplier
    WithdrawalUtil withdrawalUtil;
    // TODO: remove me when not needed
    event Logger(bytes32 data);

    constructor() {
        withdrawalUtil = new WithdrawalUtil();
    }

    // FIXME: In real system contract ETH should be minted by block producer
    function deposit() payable override public {
    }

    // TODO: remove me when beaconblockroot tests are over
    function getRoot(uint slot) public returns(bytes32) {
        bytes32 root;
        assembly {
            root := beaconblockroot(slot)
        }
        return root;
    }

    // TODO: remove me when beaconblockroot tests are over
    function verifyRoot(uint slot, bytes32 expectedRoot) public {
        bytes32 root;
        assembly {
            root := beaconblockroot(slot)
        }
        require (root == expectedRoot);
    }

    function withdraw(uint _slot, bytes32[] calldata _proof, uint64 _gIndex, Withdrawal calldata _withdrawal) override public {
        // Compute withdrawal node root
        bytes32 node = withdrawalUtil._computeWithdrawalRoot(_withdrawal);
        require(!cashed[node]);

        bytes32 root;
        assembly {
            root := beaconblockroot(_slot)
        }
        require(root != 0x0000000000000000000000000000000000000000000000000000000000000000);

        // Check is eth1 withdrawal
        bytes4 withdrawalTarget = _stripPrefix(abi.encodePacked(_withdrawal.withdrawal_credentials));
        require(withdrawalTarget == ETH1_WITHDRAWAL_ADDRESS_PREFIX);

        // Check gIndex is a part of List<Withdrawal> in BeaconState
        require(_verifyIsChild(WITHDRAWAL_GINDEX, _gIndex));

        // Verify merkle proof
        require(_verifyMerkleProof(node, _proof, _gIndex, root));

        // Pay
        address target = _toAddress(abi.encodePacked(_withdrawal.withdrawal_credentials), 12);
        cashed[node] = true;
        address payable targetPayable = payable(target);
        targetPayable.transfer(_withdrawal.amount * GWEI);
    }

    function _verifyIsChild(uint64 _gIndexParent, uint64 _gIndexChild) internal pure returns (bool) {
        uint64 gIndexCurrentParent = _gIndexChild;
        while (gIndexCurrentParent >= _gIndexParent) {
            if (_gIndexParent == gIndexCurrentParent) {
                return true;
            }
            if (gIndexCurrentParent % 2 == 1) {
                gIndexCurrentParent -= 1;
            }
            gIndexCurrentParent /= 2;
        }
        return false;
    }

    function _verifyMerkleProof(
        bytes32 _leaf,
        bytes32[] calldata _proof,
        uint64 _gIndex,
        bytes32 _root
    )
    internal
    pure
    returns (bool)
    {
        return _calculateMerkleRoot(_leaf, _proof, _gIndex) == _root;
    }

    function _calculateMerkleRoot(bytes32 _leaf, bytes32[] calldata _proof, uint64 _index) internal pure returns (bytes32) {
        assert(_proof.length == _getGeneralizedIndexLength(_index));
        for (uint i = 0; i < _proof.length; i++) {
            bytes32 hash = _proof[i];
            if (_getGeneralizedIndexBit(_index, i)) {
                _leaf = sha256(abi.encodePacked(hash, _leaf));
            } else {
                _leaf = sha256(abi.encodePacked(_leaf, hash));
            }
        }
        return _leaf;
    }

    function _getGeneralizedIndexLength(uint64 _index) internal pure returns (uint64) {
        uint res = _bitLength(_index);
        if (res == 0) {
            return 0;
        } else {
            return uint64(res - 1);
        }
    }

    function _bitLength(uint256 num) internal pure returns(uint) {
        if (num == 0) {
            return 0;
        } else {
            uint res = 0;
            uint256 remaining = num;
            while (remaining != 0) {
                uint32 minorPart = uint32(remaining & 0xFFFFFFFF);
                remaining >>= 32;
                if (remaining != 0) {
                    res += 32;
                } else {
                    res += _bitLengthForUInt32(minorPart);
                }
            }

            return res;
        }
    }

    function _bitLengthForUInt32(uint32 n) internal pure returns(uint) {
        return 32 - _numberOfLeadingZeros(n);
    }

    function  _numberOfLeadingZeros(uint32 i) internal pure returns(uint) {
        if (i == 0) {
            return 0;
        } else {
            uint n = 31;
            if (i >= 65536) {
                n -= 16;
                i >>= 16;
            }

            if (i >= 256) {
                n -= 8;
                i >>= 8;
            }

            if (i >= 16) {
                n -= 4;
                i >>= 4;
            }

            if (i >= 4) {
                n -= 2;
                i >>= 2;
            }

        return n - (i >> 1);
        }
    }

    function _getGeneralizedIndexBit(uint64 _index, uint _position) internal pure returns (bool) {
        return (_index & (1 << _position)) > 0;
    }

    function _first8BytesToUint(bytes32 _b) internal pure returns (uint64) {
        uint number;
        for (uint i = 0; i < 8; i++) {
            number = number + uint(uint8(_b[i])) * (2 ** (8 * (8 - (i + 1))));
        }
        return uint64(number);
    }

    // Strips 4 bytes prefix from bytes input
    function _stripPrefix(bytes memory _bytes) internal pure returns (bytes4) {
        require(_bytes.length >= 4, "_stripPrefix_outOfBounds");
        bytes4 tempPrefix;
        for (uint i = 0; i < 4;i++) {
            tempPrefix^=(bytes4(0xff000000)&_bytes[i])>>(i*8);
        }
        return tempPrefix;
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