const SerenityPool = artifacts.require("SerenityPool");
const DepositContract = artifacts.require("DepositContract");
const WithdrawalContract = artifacts.require("WithdrawalContract");
const Eth2Gate = artifacts.require("Eth2Gate");
const SystemContractMock = artifacts.require("SystemContractMock");
const truffleAssert = require('truffle-assertions');
const {wrapWithBuffer, convertLittleEndianToInt, generateDepositCredentials} = require("../util");

const valCredentials = {
    pubKey: "",
    withdrawalCredentials: "",
    signature: "",
    depositRoot: "",
    voluntaryExit: "0x", // TODO
    exitSignature: "0x", // TODO
}

contract('SerenityPool', (accounts) => {
    before(async () => {
        // ETH2 Withdrawals system contract mock (no checks)
        systemContractInstance = await SystemContractMock.new();
        assert.ok(systemContractInstance);
        let ether99 = web3.utils.toWei("99", 'ether');
        await systemContractInstance.deposit({from: accounts[2], value: ether99})
        let actualBalance = await web3.eth.getBalance(systemContractInstance.address);
        assert.strictEqual(actualBalance, ether99.toString(), "System contract was not funded");
    });
    beforeEach(async () => {
        // ETH2 Deposit Contract in ETH1
        depositInstance = await DepositContract.new();
        assert.ok(depositInstance);

        // Mock of ETH2 Messages gate
        eth2Gate = await Eth2Gate.new();
        assert.ok(eth2Gate);

        // Shared validator ownership pool
        poolInstance = await SerenityPool.new(depositInstance.address, eth2Gate.address, systemContractInstance.address);
        assert.ok(poolInstance);
        const creds = await generateDepositCredentials(wrapWithBuffer(poolInstance.address),
            wrapWithBuffer(WithdrawalContract.bytecode));
        valCredentials.pubKey = '0x' + creds.pubkey;
        valCredentials.withdrawalCredentials = '0x' + creds.withdrawalCredentials;
        valCredentials.signature = '0x' + creds.signature;
        valCredentials.depositRoot = '0x' + creds.depositRoot;

        // Make deposit
        // FIXME: not sure that prefund is enough for several test-deposits
        await poolInstance.preLoadCredentials(
            valCredentials.pubKey,
            valCredentials.withdrawalCredentials,
            valCredentials.signature,
            valCredentials.depositRoot,
            valCredentials.voluntaryExit,
            valCredentials.exitSignature,
            {from: accounts[0]}
        );
        let ether1 = web3.utils.toWei("1", 'ether');
        let ether1gwei = web3.utils.fromWei(ether1, 'Gwei');
        let tx1 = await poolInstance.deposit({from: accounts[3], value: ether1})
        truffleAssert.eventEmitted(tx1, 'NewFund', (ev) => {
            return ev._from === accounts[3] && ev._value == ether1gwei;
        });
        let ether31 = web3.utils.toWei("31", 'ether');
        let ether31gwei = web3.utils.fromWei(ether31, 'Gwei');
        let tx31 = await poolInstance.deposit({from: accounts[1], value: ether31})
        truffleAssert.eventEmitted(tx31, 'NewFund', (ev) => {
            return ev._from === accounts[1] && ev._value == ether31gwei;
        });
        truffleAssert.eventEmitted(tx31, 'NewValidator', (ev) => {
            return ev._pubKey === valCredentials.pubKey;
        });
        let nestedTx = await truffleAssert.createTransactionResult(depositInstance, tx31.tx);
        truffleAssert.eventEmitted(nestedTx, 'DepositEvent', (ev) => {
            return ev.pubkey === valCredentials.pubKey &&
                ev.withdrawal_credentials === valCredentials.withdrawalCredentials &&
                convertLittleEndianToInt(ev.amount) == web3.utils.fromWei(web3.utils.toWei("32", 'ether'), 'Gwei') &&
                ev.signature === valCredentials.signature &&
                convertLittleEndianToInt(ev.index) === '0';
        });
        const unclaimed = await poolInstance.getUnclaimed.call();
        assert.strictEqual(
            unclaimed.valueOf().toString(),
            '0',
            "0 ethers should be unclaimed as 32eth were sent to deposit contract"
        );
    });
    it('Withdrawal with claim user funds should work', async () => {
        const withdrawal = {
            "validator_index": "42",
            "withdrawal_credentials": valCredentials.withdrawalCredentials,
            "withdrawn_epoch": "30",
            "amount": "32500000000" // 32.5 ETH in Gwei
        }
        const withdrawalContractAddress = '0x' + valCredentials.withdrawalCredentials.substr(26);
        let withdrawalContractInstance = await WithdrawalContract.at(withdrawalContractAddress);
        let tx = await poolInstance.withdraw(valCredentials.pubKey, 123, [], 123, withdrawal);
        let nestedTx = await truffleAssert.createTransactionResult(withdrawalContractInstance, tx.tx);
        truffleAssert.eventEmitted(nestedTx, 'Received', (ev) => {
            return ev._sender === systemContractInstance.address &&
                ev._value.toString() === web3.utils.toWei(withdrawal.amount, 'Gwei').toString();
        });
        let account1PayoutWei = web3.utils.toWei(
            web3.utils.toBN(31 * 65).mul(web3.utils.toBN(10).pow(web3.utils.toBN(18))).div(web3.utils.toBN(64))
            , 'wei'); // 65/64 = 32.5/32
        truffleAssert.eventEmitted(tx, 'Payout', (ev) => {
            return ev._investor === accounts[1] &&
                ev._amount.toString() === web3.utils.fromWei(account1PayoutWei, 'Gwei').toString();
        });
        let account3PayoutWei = web3.utils.toWei(
            web3.utils.toBN(65).mul(web3.utils.toBN(10).pow(web3.utils.toBN(18))).div(web3.utils.toBN(64))
            , 'wei'); // 65/64 = 32.5/32
        truffleAssert.eventEmitted(tx, 'Payout', (ev) => {
            return ev._investor === accounts[3] &&
                ev._amount.toString() === web3.utils.fromWei(account3PayoutWei, 'Gwei').toString();
        });

        // Claim money by users
        let gasPrice = web3.utils.toBN(SerenityPool.class_defaults.gasPrice);
        let before1 = await web3.eth.getBalance(accounts[1]);
        let redeemTx1 = await poolInstance.redeem({from: accounts[1]});
        let after1 = await web3.eth.getBalance(accounts[1]);
        let gasUsedWei1 = web3.utils.toBN(redeemTx1.receipt.gasUsed).mul(gasPrice);
        let bnDelta1 = web3.utils.toBN(after1).sub(web3.utils.toBN(before1)).add(gasUsedWei1);
        assert.strictEqual(bnDelta1.toString(), account1PayoutWei.toString());
        let before3 = await web3.eth.getBalance(accounts[3]);
        let redeemTx3 = await poolInstance.redeem({from: accounts[3]});
        let after3 = await web3.eth.getBalance(accounts[3]);
        let gasUsedWei3 = web3.utils.toBN(redeemTx3.receipt.gasUsed).mul(gasPrice);
        let bnDelta3 = web3.utils.toBN(after3).sub(web3.utils.toBN(before3)).add(gasUsedWei3);
        assert.strictEqual(bnDelta3.toString(), account3PayoutWei.toString());
    });
});
