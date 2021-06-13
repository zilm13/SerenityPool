// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.8.2;

import "./../SystemContract.sol";
import "./../structs/Withdrawal.sol";

pragma experimental ABIEncoderV2;
pragma experimental ETH2OpCodes;

contract TestableSystemContract is SystemContract {
    function computeWithdrawalRoot(Withdrawal calldata withdrawal) public returns (bytes32) {
        return withdrawalUtil._computeWithdrawalRoot(withdrawal);
    }

    function verifyIsWithdrawalChild(uint64 gIndexChild) pure public returns (bool) {
        return _verifyIsChild(WITHDRAWAL_GINDEX, gIndexChild);
    }

    function verifyMerkleProof(
        bytes32 leaf,
        bytes32[] calldata proof,
        uint64 gIndex,
        bytes32 root
    )
    pure
    public
    returns (bool)
    {
        return _verifyMerkleProof(leaf, proof, gIndex, root);
    }
}