const TestableSystemContract = artifacts.require("TestableSystemContract");
const truffleAssert = require('truffle-assertions');

const withdrawalProof = {
    stateRoot: "0x854662e7be46468c332ab66b520ebaec0ecabf24ccce23fa57891a27ba183203",
    slot: 252,
    proof: [
        "0x0000000000000000000000000000000000000000000000000000000000000000",
        "0xf5a5fd42d16a20302798ef6ed309979b43003d2320d9f0e8ea9831a92759fb4b",
        "0xdb56114e00fdd4c1f85c892bf35ac9a89289aaecb1ebd0a96cde606a748b5d71",
        "0xc78009fdf07fc56a11f122370658a353aaa542ed63e44c4bc15ff4cd105ab33c",
        "0x536d98837f2dd165a55d5eeae91485954472d56f246df256bf3cae19352a123c",
        "0x9efde052aa15429fae05bad4d0b1d7c64da64d03d7a1854a588c2cb8430c0d30",
        "0xd88ddfeed400a8755596b21942c1497e114c302e6118290f91e6772976041fa1",
        "0x87eb0ddba57e35f6d286673802a4af5975e22506c7cf4c64bb6be5ee11527f2c",
        "0x26846476fd5fc54a5d43385167c95144f2643f533cc85bb9d16b782f8d7db193",
        "0x506d86582d252405b840018792cad2bf1259f1ef5aa5f887e13cb2f0094f51e1",
        "0xffff0ad7e659772f9534c195c815efc4014ef1e1daed4404c06385d11192e92b",
        "0x6cf04127db05441cd833107a52be852868890e4317e6a02ab47683aa75964220",
        "0xb7d05f875f140027ef5118a2247bbb84ce8f2f0f1123623085daf7960c329f5f",
        "0xdf6af5f5bbdb6be9ef8aa618e4bf8073960867171e29676f8b284dea6a08a85e",
        "0xb58d900f5e182e3c50ef74969ea16c7726c549757cc23523c369587da7293784",
        "0xd49a7502ffcfb0340b1d7885688500ca308161a7f96b62df9d083b71fcc8f2bb",
        "0x8fe6b1689256c0d385f42f5bbe2027a22c1996e110ba97c171d3e5948de92beb",
        "0x8d0d63c39ebade8509e0ae3c9c3876fb5fa112be18f905ecacfecb92057603ab",
        "0x95eec8b2e541cad4e91de38385f2e046619f54496c2382cb6cacd5b98c26f5a4",
        "0xf893e908917775b62bff23294dbbe3a1cd8e6cc1c35b4801887b646a6f81f17f",
        "0xcddba7b592e3133393c16194fac7431abf2f5485ed711db282183c819e08ebaa",
        "0x8a8d7fe3af8caa085a7639a832001457dfb9128a8061142ad0335629ff23ff9c",
        "0xfeb3c337d7a51a6fbf00b9e34c52e1c9195c969bd4e7a0bfd51d5c5bed9c1167",
        "0xe71f0aa83cc32edfbefa9f4d3e0174ca85182eec9f3a09f6a6c0df6377a510d7",
        "0x31206fa80a50bb6abe29085058f16212212a60eec8f049fecb92d8c8e0a84bc0",
        "0x21352bfecbeddde993839f614c3dac0a3ee37543f9b412b16199dc158e23b544",
        "0x619e312724bb6d7c3153ed9de791d764a366b389af13c58bf8a8d90481a46765",
        "0x7cdd2986268250628d0c10e385c58c6191e6fbe05191bcc04f133f2cea72c1c4",
        "0x848930bd7ba8cac54661072113fb278869e07bb8587f91392933374d017bcbe1",
        "0x8869ff2c22b28cc10510d9853292803328be4fb0e80495e8bb8d271f5b889636",
        "0xb5fe28e79f1b850f8658246ce9b6a1e7b49fc06db7143e8fe0b4f2b0c5523a5c",
        "0x985e929f70af28d0bdd1a90a808f977f597c7c778c489e98d3bd8910d31ac0f7",
        "0xc6f67e02e6e4e1bdefb994c6098953f34636ba2b6ca20a4721d2b26a886722ff",
        "0x1c9a7e5ff1cf48b4ad1582d3f4e4a1004f3b20d8c5a2b71387a4254ad933ebc5",
        "0x2f075ae229646b6f6aed19a5e372cf295081401eb893ff599b3f9acc0c0d3e7d",
        "0x328921deb59612076801e8cd61592107b5c67c79b846595cc6320c395b46362c",
        "0xbfb909fdb236ad2411b4e4883810a074b840464689986c3f8a8091827e17c327",
        "0x55d8fb3687ba3ba49f342c77f5a1f89bec83d811446e1a467139213d640b6a74",
        "0xf7210d4f8e7e1039790e7bf4efa207555a10a6db1dd4b95da313aaa88b88fe76",
        "0xad21b516cbc645ffe34ab5de1c8aef8cd4e7f8d2b51e8e1456adc7563cda206f",
        "0x0100000000000000000000000000000000000000000000000000000000000000",
        "0x536d98837f2dd165a55d5eeae91485954472d56f246df256bf3cae19352a123c",
        "0x8273c7a980cf09af613d6030553a6eb36c40674e81ce47a972391a36386f8ecd",
        "0xe9d943b2f56e7c971122b2e9221fedd6d7502e8679fbf1f312c8f2fbb4ed9721",
        "0xbdcf82fe7ea62cf8e485a8903e380dea02eb20aad4bfc2eed07233a2d3eb5ddb",
        "0x7b215a73b51222078c7be26bf00017ce4d835c8235fc5595040df71646e7ee9c",
        "0x4184b1e1ddb9374ec1d2342b6dd68cff805f4a6b3882c0076ed0916890e824ec",
        "0x6c9b4b09f216dc06f29013510592d318a810ea4b79e174718f931c6a17d1124b",
        "0x45c342f80c0150d3a817d5df1d8b37971a8d6d5abfd0150acf67f06d6a69f775"
    ],
    index: "804842511532032",
    withdrawal: {
        "pubkeyHash": "0x8210e6a59d1ede86277c7fec7893f270a075c9f67c465e50308c317dd98c0eb4",
        "withdrawalTarget": "0x01000000",
        "withdrawalCredentials": "0x010000000000000000000000ed3f2a4f6b1f89b1be9432b712ac8944159ff097",
        "amount": "32000000000",
        "epoch": "30"
    }
};
const withdrawalRoot = "0xc8674de0f4e39ac81ac06a210742d91df18b03d76c713dac20f06976224801ab";

contract('SystemContract', (accounts) => {
    before(async () => {
        testableSystemContractInstance = await TestableSystemContract.new();
        assert.ok(testableSystemContractInstance);
    });
    it('Validate Withdrawal root', async () => {
        let root = await testableSystemContractInstance.computeWithdrawalRoot.call(withdrawalProof.withdrawal);
        assert.strictEqual(root, withdrawalRoot);
    });
    it('Validate withdrawal child gIndex', async () => {
        let result1 = await testableSystemContractInstance.verifyIsWithdrawalChild.call(withdrawalProof.index);
        assert.strictEqual(result1, true);
        let result2 = await testableSystemContractInstance.verifyIsWithdrawalChild.call(367);
        assert.strictEqual(result2, false);
        let result3 = await testableSystemContractInstance.verifyIsWithdrawalChild.call(731);
        assert.strictEqual(result3, false);
        let result4 = await testableSystemContractInstance.verifyIsWithdrawalChild.call(734);
        assert.strictEqual(result4, false);
    });
    it('Verify merkle proof', async () => {
        let result1 = await testableSystemContractInstance.verifyMerkleProof.call(
            withdrawalRoot,
            withdrawalProof.proof,
            withdrawalProof.index,
            withdrawalProof.stateRoot
        );
        assert.strictEqual(result1, true);
        let result2 = await testableSystemContractInstance.verifyMerkleProof.call(
            "0xc06b65e847ece47e475e5e7653f201efd583abacee042ad85cd86c403c4bb6d5", // wrong withdrawal node
            withdrawalProof.proof,
            withdrawalProof.index,
            withdrawalProof.stateRoot
        );
        assert.strictEqual(result2, false);
        let corruptedProof = withdrawalProof.proof.slice(0, withdrawalProof.proof.length - 1);
        corruptedProof.push("0xb58d900f5e182e3c50ef74969ea16c7726c549757cc23523c369587da7293785");
        let result3 = await testableSystemContractInstance.verifyMerkleProof.call(
            withdrawalRoot,
            corruptedProof,
            withdrawalProof.index,
            withdrawalProof.stateRoot
        );
        assert.strictEqual(result3, false);
        await truffleAssert.fails(testableSystemContractInstance.verifyMerkleProof.call(
            withdrawalRoot,
            withdrawalProof.proof,
            withdrawalProof.index + 1,
            withdrawalProof.stateRoot
        ), "VM Exception while processing transaction: revert");
        let result5 = await testableSystemContractInstance.verifyMerkleProof.call(
            withdrawalRoot,
            withdrawalProof.proof,
            withdrawalProof.index,
            "0x4a61a847b0548cf51fd44e34c7eb1835ba994f6d9c10dd0f5df1f7634385731d" // wrong root
        );
        assert.strictEqual(result5, false);
    });
});
