const SerenityPool = artifacts.require("SerenityPool");
const DepositContract = artifacts.require("DepositContract");
const WithdrawalContract = artifacts.require("WithdrawalContract");
const truffleAssert = require('truffle-assertions');
const {wrapWithBuffer, convertLittleEndianToInt, generateDepositCredentials} = require("../util");

const valCredentials = {
    pubkey: "",
    withdrawal_credentials: "",
    signature: "",
    deposit_root: ""
}

contract('SerenityPool', (accounts) => {
    beforeEach(async () => {
        depositInstance = await DepositContract.new();
        assert.ok(depositInstance);
        poolInstance = await SerenityPool.new(depositInstance.address);
        assert.ok(poolInstance);
        const creds = await generateDepositCredentials(wrapWithBuffer(poolInstance.address),
            wrapWithBuffer(WithdrawalContract.bytecode));
        valCredentials.pubkey = '0x' + creds.pubkey;
        valCredentials.withdrawal_credentials = '0x' + creds.withdrawal_credentials;
        valCredentials.signature = '0x' + creds.signature;
        valCredentials.deposit_root = '0x' + creds.deposit_root;
    })
    it('should have 0 at start', async () => {
        const unclaimed = await poolInstance.getUnclaimed.call();
        assert.equal(unclaimed.valueOf(), 0, "0 wasn't initial unclaimed funding");
    });
    it('should have something after deposit', async () => {
        let accounts = await web3.eth.getAccounts();
        let loadTx = await poolInstance.preLoadCredentials(valCredentials.pubkey,
            valCredentials.withdrawal_credentials,
            valCredentials.signature,
            valCredentials.deposit_root, {from: accounts[0]});
        truffleAssert.prettyPrintEmittedEvents(loadTx);
        let ether10 = web3.utils.toWei("10", 'ether');
        let ether10gwei = web3.utils.fromWei(ether10, 'Gwei');
        let tx = await poolInstance.deposit({from: accounts[1], value: ether10})
        truffleAssert.eventEmitted(tx, 'New', (ev) => {
            return ev._from === accounts[1] && ev._value == ether10gwei;
        });
        const unclaimed = await poolInstance.getUnclaimed.call();
        assert.equal(unclaimed.valueOf(), ether10gwei, "10 ethers should be unclaimed");
    });
    it('should deposit to deposit contract', async () => {
        let accounts = await web3.eth.getAccounts();
        await poolInstance.preLoadCredentials(valCredentials.pubkey,
            valCredentials.withdrawal_credentials,
            valCredentials.signature,
            valCredentials.deposit_root, {from: accounts[0]})
        let ether32 = web3.utils.toWei("32", 'ether');
        let ether32gwei = web3.utils.fromWei(ether32, 'Gwei');
        let tx = await poolInstance.deposit({from: accounts[1], value: ether32})
        truffleAssert.eventEmitted(tx, 'New', (ev) => {
            return ev._from === accounts[1] && ev._value == ether32gwei;
        });
        truffleAssert.eventEmitted(tx, 'NewValidator', (ev) => {
            return ev._pubkey === valCredentials.pubkey;
        });
        let nestedTx = await truffleAssert.createTransactionResult(depositInstance, tx.tx);
        truffleAssert.eventEmitted(nestedTx, 'DepositEvent', (ev) => {
            return ev.pubkey === valCredentials.pubkey &&
                ev.withdrawal_credentials === valCredentials.withdrawal_credentials &&
                convertLittleEndianToInt(ev.amount) == ether32gwei &&
                ev.signature === valCredentials.signature &&
                convertLittleEndianToInt(ev.index) == 0;
        });
        const unclaimed = await poolInstance.getUnclaimed.call();
        assert.equal(unclaimed.valueOf(), 0, "0 ethers should be unclaimed as 32eth were sent to deposit contract");
    });
});
