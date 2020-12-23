const SerenityPool = artifacts.require("SerenityPool");
const DepositContract = artifacts.require("DepositContract");
const truffleAssert = require('truffle-assertions');

var valCredentials = {
    pubkey: "0x8c24bbc727f209832d35ef00d6a79f867a6a00a5f4a3e19d3868c4d0b76d185cdccca40804a25176a72a66dcbee0f6e9",
    withdrawal_credentials: "0x000c1c9c752e29a81a929e36de6eb8a48df6992d9d54e4039d61a98f22d2c0c5",
    signature: "0x968b94e8580704747350083c04f3079961ed654fd74523cce7f3d5e1a2a7193a10ada2c5835a7cc1dc220a4c24e5d86b12a8677f6097d3ae23fafbabad666c53e83b95fdba8f1d605d9a383a0cb3af5d61c0adbf6b78016eef366e3a4c979cd0",
    deposit_root: "0xb191e72eba966a5d8409fae2c4e65b1475c16a024167e27571c5d30774991fa3"
}

function convertLittleEndianToInt(str) {
    if (str.startsWith("0x")) {
        str = str.slice(2);
    }
    var data = str.match(/../g);

    // Create a buffer
    var buf = new ArrayBuffer(8);
    // Create a data view of it
    var view = new DataView(buf);

    // set bytes
    data.forEach(function (b, i) {
        view.setUint8(i, parseInt(b, 16));
    });

    // get an int64 with little endian
    var res = view.getBigInt64(0, 1);
    return res.toString(10);
}

contract('SerenityPool', (accounts) => {
    beforeEach(async () => {
        depositInstance = await DepositContract.new();
        assert.ok(depositInstance);
        poolInstance = await SerenityPool.new(depositInstance.address);
        assert.ok(poolInstance);
    })
    it('should have 0 at start', async () => {
        const unclaimed = await poolInstance.getUnclaimed.call();
        assert.equal(unclaimed.valueOf(), 0, "0 wasn't initial unclaimed funding");
    });
    it('should have something after deposit', async () => {
        let accounts = await web3.eth.getAccounts();
        await poolInstance.preLoadCredentials(valCredentials.pubkey,
            valCredentials.withdrawal_credentials,
            valCredentials.signature,
            valCredentials.deposit_root,{from: accounts[0]})
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
            valCredentials.deposit_root,{from: accounts[0]})
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
