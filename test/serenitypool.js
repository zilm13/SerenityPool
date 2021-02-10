const SerenityPool = artifacts.require("SerenityPool");
const DepositContract = artifacts.require("DepositContract");
const WithdrawalContract = artifacts.require("WithdrawalContract");
const SystemContract = artifacts.require("SystemContract");
const Eth2Gate = artifacts.require("Eth2Gate");
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
        // ETH2 Withdrawals system contract
        systemContractInstance = await SystemContract.new();
        assert.ok(systemContractInstance);
        let ether99 = web3.utils.toWei("99", 'ether');
        await systemContractInstance.deposit({from: accounts[0], value: ether99})
        let actualBalance = await web3.eth.getBalance(systemContractInstance.address);
        let expectedBalance = web3.utils.toBN(ether99);
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
        poolInstance = await SerenityPool.new(depositInstance.address, eth2Gate.address);
        assert.ok(poolInstance);
        const creds = await generateDepositCredentials(wrapWithBuffer(poolInstance.address),
            wrapWithBuffer(WithdrawalContract.bytecode));
        valCredentials.pubKey = '0x' + creds.pubkey;
        valCredentials.withdrawalCredentials = '0x' + creds.withdrawalCredentials;
        valCredentials.signature = '0x' + creds.signature;
        valCredentials.depositRoot = '0x' + creds.depositRoot;
    });
    it('should have 0 at start', async () => {
        const unclaimed = await poolInstance.getUnclaimed.call();
        assert.strictEqual(unclaimed.valueOf().toString(), '0', "0 wasn't initial unclaimed funding");
    });
    it('should have something after deposit', async () => {
        let accounts = await web3.eth.getAccounts();
        let loadTx = await poolInstance.preLoadCredentials(
            valCredentials.pubKey,
            valCredentials.withdrawalCredentials,
            valCredentials.signature,
            valCredentials.depositRoot,
            valCredentials.voluntaryExit,
            valCredentials.exitSignature,
            {from: accounts[0]}
        );
        truffleAssert.prettyPrintEmittedEvents(loadTx);
        let ether10 = web3.utils.toWei("10", 'ether');
        let ether10gwei = web3.utils.fromWei(ether10, 'Gwei');
        let tx = await poolInstance.deposit({from: accounts[1], value: ether10})
        truffleAssert.eventEmitted(tx, 'NewFund', (ev) => {
            return ev._from === accounts[1] && ev._value == ether10gwei;
        });
        const unclaimed = await poolInstance.getUnclaimed.call();
        assert.strictEqual(unclaimed.valueOf().toString(), ether10gwei, "10 ethers should be unclaimed");
    });
    it('should deposit to deposit contract', async () => {
        let accounts = await web3.eth.getAccounts();
        await poolInstance.preLoadCredentials(
            valCredentials.pubKey,
            valCredentials.withdrawalCredentials,
            valCredentials.signature,
            valCredentials.depositRoot,
            valCredentials.voluntaryExit,
            valCredentials.exitSignature,
            {from: accounts[0]}
        );
        let ether32 = web3.utils.toWei("32", 'ether');
        let ether32gwei = web3.utils.fromWei(ether32, 'Gwei');
        let tx = await poolInstance.deposit({from: accounts[1], value: ether32})
        truffleAssert.eventEmitted(tx, 'NewFund', (ev) => {
            return ev._from === accounts[1] && ev._value == ether32gwei;
        });
        truffleAssert.eventEmitted(tx, 'NewValidator', (ev) => {
            return ev._pubKey === valCredentials.pubKey;
        });
        let nestedTx = await truffleAssert.createTransactionResult(depositInstance, tx.tx);
        truffleAssert.eventEmitted(nestedTx, 'DepositEvent', (ev) => {
            return ev.pubkey === valCredentials.pubKey &&
                ev.withdrawal_credentials === valCredentials.withdrawalCredentials &&
                convertLittleEndianToInt(ev.amount) == ether32gwei &&
                ev.signature === valCredentials.signature &&
                convertLittleEndianToInt(ev.index) == 0;
        });
        const unclaimed = await poolInstance.getUnclaimed.call();
        assert.strictEqual(unclaimed.valueOf().toString(), '0', "0 ethers should be unclaimed as 32eth were sent to deposit contract");
    });
});
