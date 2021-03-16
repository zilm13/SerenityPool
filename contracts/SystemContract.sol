// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.8.2;

import "./structs/Withdrawal.sol";

pragma experimental ABIEncoderV2;
pragma experimental ETH2OpCodes;

// Mock of withdrawals system contract
interface ISystemContract {
    function withdraw(uint slot, bytes32[] calldata proof, uint64 gIndex, Withdrawal calldata withdrawal) external;
}

contract SystemContract is ISystemContract {
    mapping(bytes32 => bool) cashed;
    uint64 constant WITHDRAWAL_GINDEX = 366;
    bytes4 constant ETH1_WITHDRAWAL_ADDRESS_PREFIX = 0x01000000;
    // TODO: remove me when not needed
    event Logger(bytes32 data);

    // FIXME: In real system contract ETH should be minted by block producer
    function deposit() payable public {
    }

    // TODO: remove me when beaconblockroot tests are over
    function getRoot(uint slot) public returns(bytes32) {
        bytes32 root;
        assembly {
            root := beaconblockroot(slot)
        }
        emit Logger(root);
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
        require(!cashed[_withdrawal.pubkeyHash]);
        bytes32 root;
        assembly {
            root := beaconblockroot(_slot)
        }
        require(root != 0x0000000000000000000000000000000000000000000000000000000000000000);

        // Check is eth1 withdrawal
        require(_withdrawal.withdrawalTarget == ETH1_WITHDRAWAL_ADDRESS_PREFIX);

        // Check gIndex is a part of List<Withdrawal> in BeaconState
        require(_verifyIsChild(WITHDRAWAL_GINDEX, _gIndex));

        // Compute withdrawal node root
        bytes32 node = _computeWithdrawalRoot(_withdrawal);

        // Verify merkle proof
        require(_verifyMerkleProof(node, _proof, _gIndex, root));

        // Pay
        address target = _toAddress(_withdrawal.withdrawalCredentials, 12);
        cashed[_withdrawal.pubkeyHash] = true;
        address payable targetPayable = payable(target);
        targetPayable.transfer(_withdrawal.amount);
    }

    // Compute withdrawal root (`Withdrawal` hash tree root)
    function _computeWithdrawalRoot(Withdrawal memory _withdrawal) internal returns (bytes32) {
        bytes32 two_root = sha256(abi.encodePacked(
                sha256(abi.encodePacked(_withdrawal.pubkeyHash, _withdrawal.withdrawalTarget, bytes28(0))),
                sha256(abi.encodePacked(
                        _withdrawal.withdrawalCredentials,
                            _toLittleEndian64(_withdrawal.amount),
                            bytes24(0)
                    ))
            ));
        bytes32 three_root = sha256(abi.encodePacked(
                sha256(abi.encodePacked(_toLittleEndian64(_withdrawal.epoch), bytes32(0), bytes24(0))),
                sha256(abi.encodePacked(bytes32(0), bytes32(0)))
            ));
        bytes32 node = sha256(abi.encodePacked(two_root, three_root));
        emit Logger(node);
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
        return uint64(_log2Floor(_index));
    }

    // Method copy-pasted from https://ethereum.stackexchange.com/a/30168
    function _log2Floor(uint x) internal pure returns (uint){
        uint y;
        assembly {
            let arg := x
            x := sub(x,1)
            x := or(x, div(x, 0x02))
            x := or(x, div(x, 0x04))
            x := or(x, div(x, 0x10))
            x := or(x, div(x, 0x100))
            x := or(x, div(x, 0x10000))
            x := or(x, div(x, 0x100000000))
            x := or(x, div(x, 0x10000000000000000))
            x := or(x, div(x, 0x100000000000000000000000000000000))
            x := add(x, 1)
            let m := mload(0x40)
            mstore(m,           0xf8f9cbfae6cc78fbefe7cdc3a1793dfcf4f0e8bbd8cec470b6a28a7a5a3e1efd)
            mstore(add(m,0x20), 0xf5ecf1b3e9debc68e1d9cfabc5997135bfb7a7a3938b7b606b5b4b3f2f1f0ffe)
            mstore(add(m,0x40), 0xf6e4ed9ff2d6b458eadcdf97bd91692de2d4da8fd2d0ac50c6ae9a8272523616)
            mstore(add(m,0x60), 0xc8c0b887b0a8a4489c948c7f847c6125746c645c544c444038302820181008ff)
            mstore(add(m,0x80), 0xf7cae577eec2a03cf3bad76fb589591debb2dd67e0aa9834bea6925f6a4a2e0e)
            mstore(add(m,0xa0), 0xe39ed557db96902cd38ed14fad815115c786af479b7e83247363534337271707)
            mstore(add(m,0xc0), 0xc976c13bb96e881cb166a933a55e490d9d56952b8d4e801485467d2362422606)
            mstore(add(m,0xe0), 0x753a6d1b65325d0c552a4d1345224105391a310b29122104190a110309020100)
            mstore(0x40, add(m, 0x100))
            let magic := 0x818283848586878898a8b8c8d8e8f929395969799a9b9d9e9faaeb6bedeeff
            let shift := 0x100000000000000000000000000000000000000000000000000000000000000
            let a := div(mul(x, magic), shift)
            y := div(mload(add(m,sub(255,a))), shift)
            y := add(y, mul(256, gt(arg, 0x8000000000000000000000000000000000000000000000000000000000000000)))
        }
        return (y - 1);
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

    // Converts bytes to address
    // Copied from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
    function _toAddress(bytes32 _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
    }
}