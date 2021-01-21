const bls = require('@chainsafe/bls');
const assert  = require('assert');
const util = require('../index.js');

describe('Utils Test', () => {
    it('CREATE2 calculation', () => {
        let from = Buffer('0123456789012345678901234567890123456789', 'hex');
        let salt = Buffer('0000000000000000000000000000000000000000000000000000000000000314', 'hex');
        let callData = Buffer('6080604052348015600f57600080fd5b50603580601d6000396000f3006080604052600080fd00a165627a7a72305820a63607f79a5e21cdaf424583b9686f2aa44059d70183eb9846ccfa086405716e0029', 'hex');
        assert.strictEqual(util.calcCreate2Address(from, salt, callData).toString('hex'), 'd26e42c8a0511c19757f783402231cf82b2bdf59');
    });
    it('DepositMessage signing', async () => {
        await bls.init("herumi");
        const expectedSignature = Buffer('968b94e8580704747350083c04f3079961ed654fd74523cce7f3d5e1a2a7193a10ada2c5835a7cc1dc220a4c24e5d86b12a8677f6097d3ae23fafbabad666c53e83b95fdba8f1d605d9a383a0cb3af5d61c0adbf6b78016eef366e3a4c979cd0', 'hex');
        const secretKey = Buffer('5f72c1c821da2721d46f34783667e681304a10a29d20e094bf43e8ed9b5e60cf', 'hex');
        const depositMessageRoot = Buffer('5ad9f34bc9def9d1a8a1d26534a1d393fa6cb6714faf35b4caf5861dc03a58b0', 'hex');
        const domain = util.computeDepositDomain();
        const signingRoot = util.computeSigningRoot(depositMessageRoot, domain);
        assert.strictEqual(Buffer.from(bls.sign(secretKey, signingRoot).buffer).toString('hex'), expectedSignature.toString('hex'));

    });
    it('DepositMessage root calculation', () => {
        const pubKey = Buffer('8c24bbc727f209832d35ef00d6a79f867a6a00a5f4a3e19d3868c4d0b76d185cdccca40804a25176a72a66dcbee0f6e9', 'hex')
        const withdrawalCredentials = Buffer('000c1c9c752e29a81a929e36de6eb8a48df6992d9d54e4039d61a98f22d2c0c5', 'hex');
        const expectedDepositMessageRoot = Buffer('5ad9f34bc9def9d1a8a1d26534a1d393fa6cb6714faf35b4caf5861dc03a58b0', 'hex');
        assert.strictEqual(util.computeDepositMessageRoot(pubKey, withdrawalCredentials, util.DEPOSIT_AMOUNT).toString('hex'), expectedDepositMessageRoot.toString('hex'));
    });
    it('DepositData root calculation', () => {
        const pubKey = Buffer('8c24bbc727f209832d35ef00d6a79f867a6a00a5f4a3e19d3868c4d0b76d185cdccca40804a25176a72a66dcbee0f6e9', 'hex')
        const withdrawalCredentials = Buffer('000c1c9c752e29a81a929e36de6eb8a48df6992d9d54e4039d61a98f22d2c0c5', 'hex');
        const signature = Buffer('968b94e8580704747350083c04f3079961ed654fd74523cce7f3d5e1a2a7193a10ada2c5835a7cc1dc220a4c24e5d86b12a8677f6097d3ae23fafbabad666c53e83b95fdba8f1d605d9a383a0cb3af5d61c0adbf6b78016eef366e3a4c979cd0', 'hex');
        const expectedDepositRoot = Buffer('b191e72eba966a5d8409fae2c4e65b1475c16a024167e27571c5d30774991fa3', 'hex');
        assert.strictEqual(util.computeDepositDataRoot(pubKey, withdrawalCredentials, util.DEPOSIT_AMOUNT, signature).toString('hex'), expectedDepositRoot.toString('hex'));
    });
    it('Function signature calculation', () => {
        assert.strictEqual(util.calculateFunctionSignature("sendMessage(string,address)"), "c48d6d5e");
    });
});