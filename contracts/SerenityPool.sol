// SPDX-License-Identifier: MIT
pragma solidity >=0.6.11 <0.8.2;
pragma experimental ABIEncoderV2;

// This is non-production example of Pool
// Don't use it, it's easy to hack one

import "./lib/DepositQueue.sol";
import "./lib/FundDeque.sol";
import "./DepositContract.sol";
import "./structs/Validator.sol";
import "./WithdrawalContract.sol";
import "./Eth2Gate.sol";
import "./SystemContract.sol";
import "./structs/Withdrawal.sol";
import "./structs/Fund.sol";

contract SerenityPool {
    uint64 constant VALIDATOR_DEPOSIT = 32_000_000_000; // 32 ETH
    uint256 constant VALIDATOR_TTL = 365*24*60*60; // 1 year
    bytes4 constant WITHDRAW_FUNC_SIGNATURE = 0x0968f264; // withdraw(bytes)
    uint constant FIXED = 10 ** 18; // multiplier for fixed point division operation
    uint constant GWEI = 10 ** 9; // Gwei to wei multiplier
    IDepositContract public depositContract;
    IEth2Gate public eth2Gate;
    ISystemContract public systemContract;
    address public owner;
    DepositQueue validatorQueue;
    FundDeque fundDeque;
    uint64 unclaimedFunds;
    mapping(bytes => Validator) validators;
    mapping(address => uint) payouts;

    event NewFund(address indexed _from, uint64 _value);
    event NewValidator(bytes _pubKey, uint256 _time);
    event Payout(address _investor, uint256 _amount);
    // TODO: remove me when not needed
    event Logger(uint data);

    modifier onlyOwner() {
        if (msg.sender == owner) _;
    }

    constructor(address _depositContractAddress, address _eth2GateAddress, address _systemContractAddress) {
        depositContract = IDepositContract(_depositContractAddress);
        eth2Gate = IEth2Gate(_eth2GateAddress);
        systemContract = ISystemContract(_systemContractAddress);
        unclaimedFunds = 0;
        validatorQueue = new DepositQueue();
        fundDeque = new FundDeque();
        owner = msg.sender;
    }

    // Validator hosting service owner submits credentials for future validators
    function preLoadCredentials(
        bytes calldata _pubKey,
        bytes calldata _withdrawalCredentials,
        bytes calldata _signature,
        bytes32 _depositDataRoot,
        bytes calldata _voluntaryExit,
        bytes calldata _exitSignature
    )
    public
    onlyOwner
    {
        IWithdrawalContract withdrawal = new WithdrawalContract{salt: keccak256(_pubKey)}();
        _validateWithdrawalAddress(withdrawal, _withdrawalCredentials);
        // TODO: when possible with EIP-2537 or similar bls.verify(_voluntary_exit, _exit_signature, _pubkey);
        // TODO: verify that epoch in _voluntary_exit is 1 year ahead
        // (issue: there could be a big lag between submitting credentials and starting actual validator)
        Deposit memory userDeposit =  Deposit({
            pubKey : _pubKey,
            withdrawalCredentials : _withdrawalCredentials,
            signature : _signature,
            depositDataRoot : _depositDataRoot,
            voluntaryExit: _voluntaryExit,
            exitSignature: _exitSignature,
            withdrawalContract: withdrawal
        });
		validatorQueue.enqueue(userDeposit);
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

    // TODO: WHERE IS MY TOKEN???
    function deposit() payable public {
        require(validatorQueue.isNotEmpty());
        // Check deposit amount
        require(msg.value % 1 gwei == 0, "Deposit value not multiple of gwei");
        uint depositAmount = msg.value / 1 gwei;
        require(depositAmount <= type(uint64).max, "Deposit value too high");
        uint64 depositGwei = uint64(depositAmount);
        Fund memory fund = Fund({
            from : msg.sender,
            amount : depositGwei
        });
        fundDeque.pushRight(fund);
        unclaimedFunds += depositGwei;
        makeDeposit();
        emit NewFund(msg.sender, depositGwei);
    }

    // TODO: 100% shares votes for exit -> EXIT. As we need VoluntaryExit signed by Validator, we could only
   // submit request to validator hosting.

    // Initiates VoluntaryExit.
    // Should be executed by validator hosting, but shares are protected as anyone could call it
    // TODO: store gas and fee for this operation
    function initiateExit(bytes calldata _pubKey) public {
        Validator memory validator = validators[_pubKey];
        require(block.timestamp > validator.endOfLife);
        eth2Gate.sendSignedVoluntaryExit(
            validator.voluntaryExit,
            validator.exitSignature,
            address(this),
            abi.encodeWithSignature("withdraw(bytes)", _pubKey)
        );
    }

    // Calls Withdrawal System Contract to get money from exited validator
    function withdraw(bytes calldata _pubKey, uint _slot, bytes32[] calldata _proof, uint64 _gIndex, Withdrawal calldata _withdrawal) public {
        Validator memory validator = validators[_pubKey];

        // Call withdraw system contract
        systemContract.withdraw(_slot, _proof, _gIndex, _withdrawal);

        // Claim money from withdrawal contract
        uint amount = validator.withdrawalContract.withdraw();
        amount = amount / GWEI;
        // TODO: destroy withdrawal contract

        // TODO: eat service fee

        // Split remaining funds among shares
        require(!validator.shares.isEmpty());
        uint investedAmount = 0;
        for (uint i = validator.shares.getFirstIndex(); i <= validator.shares.getLastIndex(); i++) {
            investedAmount += validator.shares.getElement(i).amount;
        }

        uint coeff = (amount * FIXED)/investedAmount;

        while (!validator.shares.isEmpty()) {
            Fund memory share = validator.shares.popLeft();
            uint shareAmount = (share.amount * coeff)/FIXED;
            payouts[share.from] = shareAmount;
            emit Payout(share.from, shareAmount);
        }
    }

    // Receiver from withdraw contract
    receive() external payable {}

    // Claims user's funds
    function redeem() public {
        require(payouts[msg.sender] != 0);
        address payable senderPayable = payable(msg.sender);
        senderPayable.transfer(payouts[msg.sender] * GWEI);
        payouts[msg.sender] = 0;
    }

    // Returns value of funds queued for validator deposits
    function getUnclaimed() view public returns (uint256) {
        return unclaimedFunds;
    }

    // Validates that provided _withdrawalCredentials matches WithdrawalContract address corresponding to validator
    function _validateWithdrawalAddress(
        IWithdrawalContract withdrawal,
        bytes calldata _withdrawalCredentials
    )
    view
    private
    {
        address withdrawalAddress = withdrawal.getAddress();
        bytes memory withdrawalCredentials = _withdrawalCredentials;
        address expectedWithdrawalAddress = _toAddress(withdrawalCredentials, 12);
        require(withdrawalAddress == expectedWithdrawalAddress);
    }

    // Recursively deposits unclaimed funds until there are enough funds to create new validators
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
                    amount : needed
                });
                Fund memory left = Fund({
                    from : fund.from,
                    amount : fund.amount - needed
                });
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

    // Sends funds to ETH2 Deposit contract, internally stores all shares info about appropriate validator deposits
    function makeIssuance(FundDeque _issuanceDeque) private {
        Deposit memory validator = validatorQueue.dequeue();
        depositContract.deposit {value: (1 gwei) * uint256(VALIDATOR_DEPOSIT)} (
            validator.pubKey,
            validator.withdrawalCredentials,
            validator.signature,
            validator.depositDataRoot
        );
        validators[validator.pubKey] =  Validator({
            withdrawalCredentials : validator.withdrawalCredentials,
            shares : _issuanceDeque,
            endOfLife: block.timestamp + VALIDATOR_TTL,
            voluntaryExit: validator.voluntaryExit,
            exitSignature: validator.exitSignature,
            withdrawalContract: validator.withdrawalContract
        });
        emit NewValidator(validator.pubKey, block.timestamp);
    }
}
