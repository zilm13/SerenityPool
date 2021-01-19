// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.7.0;
pragma experimental ABIEncoderV2;

// This is non-production example of Pool
// Don't use it, it's easy to hack one

import "./lib/DepositQueue.sol";
import "./lib/FundDeque.sol";
import "./DepositContract.sol";
import "./structs/Validator.sol";
import "./WithdrawalContract.sol";

contract SerenityPool {
    IDepositContract public depositContract;
    uint64 constant VALIDATOR_DEPOSIT = 32_000_000_000;
    uint256 constant VALIDATOR_TTL = 365*24*60*60; // 1 year
    address public owner;
    DepositQueue validatorQueue;
    FundDeque fundDeque;
    uint64 unclaimedFunds;
    mapping(bytes => Validator) validators;

    event New(address indexed _from, uint64 _value);
    event NewValidator(bytes _pubkey, uint256 _time);
    // TODO: remove me when not needed
    event Logger(bytes data);

    constructor(address depositContractAddress) public {
        depositContract = IDepositContract(depositContractAddress);
        unclaimedFunds = 0;
        validatorQueue = new DepositQueue();
        fundDeque = new FundDeque();
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender == owner) _;
    }

    function preLoadCredentials(bytes calldata _pubkey, bytes calldata _withdrawal_credentials, bytes calldata _signature, bytes32 _deposit_data_root) public onlyOwner {
        IWithdrawalContract withdrawal = new WithdrawalContract{salt: keccak256(_pubkey)}();
        address withdrawalAddress = withdrawal.getAddress();
        bytes memory withdrawal_credentials = _withdrawal_credentials;
        address expectedWithdrawalAddress = toAddress(withdrawal_credentials, 12);
        require(withdrawalAddress == expectedWithdrawalAddress);
        Deposit memory deposit = Deposit({
		    pubkey : _pubkey,
		    withdrawal_credentials : _withdrawal_credentials,
		    signature : _signature,
		    deposit_data_root : _deposit_data_root,
            withdrawalContract: withdrawal});
		validatorQueue.enqueue(deposit);
    }

    // Copied from https://github.com/GNSPS/solidity-bytes-utils/blob/master/contracts/BytesLib.sol
    function toAddress(bytes memory _bytes, uint256 _start) internal pure returns (address) {
        require(_start + 20 >= _start, "toAddress_overflow");
        require(_bytes.length >= _start + 20, "toAddress_outOfBounds");
        address tempAddress;

        assembly {
            tempAddress := div(mload(add(add(_bytes, 0x20), _start)), 0x1000000000000000000000000)
        }

        return tempAddress;
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
        // FIXME: this approach assumes that the last funder pays for deposit gas, while all intermediate not
        makeIssuance(issuanceDeque);
        makeDeposit();
    }

    function makeIssuance(FundDeque _issuanceDeque) private {
        Deposit memory validator = validatorQueue.dequeue();
        depositContract.deposit {value: (1 gwei) * uint256(VALIDATOR_DEPOSIT)} (validator.pubkey, validator.withdrawal_credentials, validator.signature, validator.deposit_data_root);
        validators[validator.pubkey] =  Validator({
            withdrawal_credentials : validator.withdrawal_credentials,
            shares : _issuanceDeque,
            end_of_life: block.timestamp + VALIDATOR_TTL,
            withdrawalContract: validator.withdrawalContract});
        emit NewValidator(validator.pubkey, block.timestamp);
    }

    // TODO: 100% shares votes for exit -> EXIT

    // TODO: Shares claim for validator funds after end of life, get their funds
    function initiateWithdrawal(bytes calldata pubkey) public returns (bool) {

    }

    function getUnclaimed() view public returns (uint256) {
        return unclaimedFunds;
    }
}
