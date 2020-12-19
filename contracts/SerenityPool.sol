// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.7.0;
pragma experimental ABIEncoderV2;

// This is non-production example of Pool
// Don't use it, it's easy to hack one

import "./lib/DepositQueue.sol";
import "./lib/FundDeque.sol";
import "./DepositContract.sol";

contract SerenityPool {
    IDepositContract public depositContract;
    uint256 VALIDATOR_DEPOSIT = 32_000_000_000_000_000_000;
    address public owner;
    DepositQueue validatorQueue;
    FundDeque fundDeque;
    uint256 unclaimedFunds;

    event New(address indexed _from, uint256 _value);

    constructor() public {
        depositContract = IDepositContract(0x345cA3e014Aaf5dcA488057592ee47305D9B3e10);
        unclaimedFunds = 0;
        validatorQueue = new DepositQueue();
        fundDeque = new FundDeque();
        owner = msg.sender;
    }

    modifier restricted() {
        if (msg.sender == owner) _;
    }

    function preLoadCredentials(bytes calldata _pubkey, bytes calldata _withdrawal_credentials, bytes calldata _signature, bytes32 _deposit_data_root) public restricted {
        Deposit memory deposit = Deposit({
		    pubkey : _pubkey,
		    withdrawal_credentials : _withdrawal_credentials,
		    signature : _signature,
		    deposit_data_root : _deposit_data_root});
		validatorQueue.enqueue(deposit);
    }

    function deposit() payable public returns (bool sufficient) {
        require(validatorQueue.isNotEmpty());
        Fund memory fund = Fund({
            from : msg.sender,
            amount : msg.value
        });
        fundDeque.pushRight(fund);
        unclaimedFunds += msg.value;
        makeDeposit();
        emit New(msg.sender, msg.value);
        return true;
    }

    function makeDeposit() private {
        if (unclaimedFunds < VALIDATOR_DEPOSIT)
            return;
        uint256 counter = 0;
        FundDeque issuanceDeque = new FundDeque();
        while (counter < VALIDATOR_DEPOSIT) {
            Fund memory fund = fundDeque.popLeft();
            uint256 needed = VALIDATOR_DEPOSIT - counter;
            if (fund.amount > needed) {
                Fund memory depositPart = Fund({
                    from : fund.from,
                    amount : needed});
                Fund memory left = Fund({
                    from : fund.from,
                    amount : fund.amount - needed});
                issuanceDeque.pushRight(depositPart);
                fundDeque.pushLeft(left);
            } else {
                counter += fund.amount;
                issuanceDeque.pushRight(fund);
            }
        }
        unclaimedFunds -= VALIDATOR_DEPOSIT;
        makeIssuance(issuanceDeque);
        makeDeposit();
    }

    function makeIssuance(FundDeque _issuanceDeque) private {
        // TODO
    }

    function getUnclaimed() view public returns (uint256) {
        return unclaimedFunds;
    }
}
