const SerenityPool = artifacts.require("SerenityPool");
const DepositContract = artifacts.require("DepositContract");
const truffleAssert = require('truffle-assertions');

contract('SerenityPool', (accounts) => {
    beforeEach(async () => {
        depositInstance = await DepositContract.new();
        assert.ok(depositInstance)
        poolInstance = await SerenityPool.new();
        assert.ok(poolInstance)
    })
    it('should have 0 at start', async () => {
        const unclaimed = await poolInstance.getUnclaimed.call();
        assert.equal(unclaimed.valueOf(), 0, "0 wasn't initial unclaimed funding");
    });
    it('should have something after deposit', async () => {
        let accounts = await web3.eth.getAccounts();
        await poolInstance.preLoadCredentials("0x8c24bbc727f209832d35ef00d6a79f867a6a00a5f4a3e19d3868c4d0b76d185cdccca40804a25176a72a66dcbee0f6e9",
            "0x000c1c9c752e29a81a929e36de6eb8a48df6992d9d54e4039d61a98f22d2c0c5",
            "0x968b94e8580704747350083c04f3079961ed654fd74523cce7f3d5e1a2a7193a10ada2c5835a7cc1dc220a4c24e5d86b12a8677f6097d3ae23fafbabad666c53e83b95fdba8f1d605d9a383a0cb3af5d61c0adbf6b78016eef366e3a4c979cd0",
            "0xb191e72eba966a5d8409fae2c4e65b1475c16a024167e27571c5d30774991fa3",{from: accounts[0]})
        let ether10 = web3.utils.toWei("10", 'ether');
        let tx = await poolInstance.deposit({from: accounts[1], value: ether10})
        truffleAssert.eventEmitted(tx, 'New', (ev) => {
            return ev._from === accounts[1] && ev._value == ether10;
        });
        const unclaimed = await poolInstance.getUnclaimed.call();
        assert.equal(unclaimed.valueOf(), ether10, "10 ethers should be unclaimed");
    });
    it('should deposit to deposit contract', async () => {
        let accounts = await web3.eth.getAccounts();
        await poolInstance.preLoadCredentials("0x8c24bbc727f209832d35ef00d6a79f867a6a00a5f4a3e19d3868c4d0b76d185cdccca40804a25176a72a66dcbee0f6e9",
            "0x000c1c9c752e29a81a929e36de6eb8a48df6992d9d54e4039d61a98f22d2c0c5",
            "0x968b94e8580704747350083c04f3079961ed654fd74523cce7f3d5e1a2a7193a10ada2c5835a7cc1dc220a4c24e5d86b12a8677f6097d3ae23fafbabad666c53e83b95fdba8f1d605d9a383a0cb3af5d61c0adbf6b78016eef366e3a4c979cd0",
            "0xb191e72eba966a5d8409fae2c4e65b1475c16a024167e27571c5d30774991fa3",{from: accounts[0]})
        let ether32 = web3.utils.toWei("32", 'ether');
        let tx = await poolInstance.deposit({from: accounts[1], value: ether32})
        truffleAssert.eventEmitted(tx, 'New', (ev) => {
            return ev._from === accounts[1] && ev._value == ether32;
        });
        const unclaimed = await poolInstance.getUnclaimed.call();
        assert.equal(unclaimed.valueOf(), 0, "0 ethers should be unclaimed as 32eth were sent to deposit contract");
        // TODO: deposit was made
    });
});
