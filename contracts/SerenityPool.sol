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
    uint64 constant VALIDATOR_DEPOSIT = 32_000_000_000;
    address public owner;
    DepositQueue validatorQueue;
    FundDeque fundDeque;
    uint64 unclaimedFunds;

    event New(address indexed _from, uint64 _value);

    constructor() public {
        depositContract = IDepositContract(0x345cA3e014Aaf5dcA488057592ee47305D9B3e10);
        unclaimedFunds = 0;
        validatorQueue = new DepositQueue();
        fundDeque = new FundDeque();
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == owner) _;
    }

    function preLoadCredentials(bytes calldata _pubkey, bytes calldata _withdrawal_credentials, bytes calldata _signature, bytes32 _deposit_data_root) public onlyOwner {
        Deposit memory deposit = Deposit({
		    pubkey : _pubkey,
		    withdrawal_credentials : _withdrawal_credentials,
		    signature : _signature,
		    deposit_data_root : _deposit_data_root});
		validatorQueue.enqueue(deposit);
    }

    function deposit() payable public returns (bool sufficient) {
        require(validatorQueue.isNotEmpty());
        // Check deposit amount
        require(msg.value % 1 gwei == 0, "Deposit value not multiple of gwei");
        uint deposit_amount = msg.value / 1 gwei;
        require(deposit_amount <= type(uint64).max, "Deposit value too high");
        uint64 deposit_gwei = uint64(deposit_amount);
        Fund memory fund = Fund({
            from : msg.sender,
            amount : deposit_gwei
        });
        fundDeque.pushRight(fund);
        unclaimedFunds += deposit_gwei;
        makeDeposit();
        emit New(msg.sender, deposit_gwei);
        return true;
    }

    function makeDeposit() private {
        if (unclaimedFunds < VALIDATOR_DEPOSIT)
            return;
        uint64 counter = 0;
        FundDeque issuanceDeque = new FundDeque();
        while (counter < VALIDATOR_DEPOSIT) {
            Fund memory fund = fundDeque.popLeft();
            uint64 needed = VALIDATOR_DEPOSIT - counter;
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
