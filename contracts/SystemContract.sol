// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.8.2;

pragma experimental ABIEncoderV2;
pragma experimental ETH2OpCodes;

// Mock of withdrawals system contract
interface ISystemContract {
    // TODO: Consider alternative input:
    // - validator index
    // - eth1 withdrawal address
    // - tree leaf with proof
    function withdraw(bytes calldata _pubKey) external;
}

contract SystemContract is ISystemContract {
    mapping(bytes => bool) cashed;

    // FIXME: In real system contract ETH should be minted by block producer
    function deposit() payable public {
    }

    function withdraw(bytes calldata _pubKey) override public {
        require(!cashed[_pubKey]);
        bytes32 pubkeyHash = keccak256(_pubKey);
        bytes32 withdrawalData;
        assembly {
            withdrawalData := withdraw(pubkeyHash)
        }
        require(withdrawalData != 0x0000000000000000000000000000000000000000000000000000000000000000);
        uint64 amount;
        address target;
        (amount, target) = _splitWithdrawal(withdrawalData);
        require(amount > 0);
        cashed[_pubKey] = true;
        address payable targetPayable = payable(target);
        targetPayable.transfer(amount);
    }

    function _splitWithdrawal(bytes32 data) internal pure returns (uint64, address) {
        address target = _toAddress(data, 12);
        uint64 amount = _first8BytesToUint(data);
        return (amount, target);
    }

    function _first8BytesToUint(bytes32 b) internal pure returns (uint64) {
        uint number;
        for (uint i = 0; i < 8; i++) {
            number = number + uint(uint8(b[i])) * (2 ** (8 * (8 - (i + 1))));
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