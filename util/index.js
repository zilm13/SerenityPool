const keccak = require('keccak');
const bls = require('@chainsafe/bls');
const ssz = require('@chainsafe/ssz');

const DEPOSIT_AMOUNT = 32 * 1_000_000_000;
exports.DEPOSIT_AMOUNT = DEPOSIT_AMOUNT

/**
 * Wraps data as byte data in Buffer. Supports Uint8Array, Buffer, str
 */
function wrapWithBuffer(data) {
   if (Buffer.isBuffer(data)){
       return data;
   }
   if(typeof data === 'string') {
       const strippedData = strip0x(data);
       return Buffer(strippedData, 'hex');
   }
   if (data instanceof Uint8Array) {
       return Buffer.from(data.buffer);
   }

   throw new TypeError('Data input is not supported');
}
exports.wrapWithBuffer = wrapWithBuffer;

/**
 * Ensures that data is Buffer
 */
function requireBuffer(data) {
    if (!Buffer.isBuffer(data)){
        throw new TypeError('Data should be a buffer');
    }
}

function strip0x(str) {
    if (str.startsWith("0x")) {
        str = str.slice(2);
    }
    return str;
}
exports.strip0x = strip0x;

/**
 * @param str hex string
 * @returns {string} little endian big int string
 */
function convertLittleEndianToInt(str) {
    str = strip0x(str);
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
exports.convertLittleEndianToInt = convertLittleEndianToInt;

function calcCreate2Address(address, salt, callData) {
    requireBuffer(address);
    requireBuffer(salt);
    requireBuffer(callData);
    let call_data_hash = wrapWithBuffer(keccak('keccak256').update(callData).digest('hex'));
    let value = Buffer.concat([Buffer.from([0xff]), address, salt, call_data_hash]);
    let hash = keccak('keccak256').update(value).digest('hex');
    return wrapWithBuffer(hash.slice(24));
}
exports.calcCreate2Address = calcCreate2Address;

async function generateDepositCredentials(mainContractAddress, withdrawalContractCallData) {
    requireBuffer(mainContractAddress);
    requireBuffer(withdrawalContractCallData);
    await bls.init("herumi");
    const secretKey = bls.SecretKey.fromKeygen();
    // pubkey
    const publicKey = secretKey.toPublicKey();
    const salt = keccak('keccak256').update(wrapWithBuffer(publicKey.toBytes())).digest('hex');
    // withdrawal_credentials
    const withdrawalContractAddress = calcCreate2Address(mainContractAddress, Buffer(salt, 'hex'), withdrawalContractCallData);
    const withdrawalCredentials = Buffer.concat([wrapWithBuffer('010000000000000000000000'), withdrawalContractAddress]);
    // signature
    const depositMessageRoot = computeDepositMessageRoot(wrapWithBuffer(publicKey.toBytes()), withdrawalCredentials, DEPOSIT_AMOUNT);
    const domain = computeDepositDomain();
    const signingRoot = computeSigningRoot(depositMessageRoot, domain);
    const signature = bls.sign(secretKey.toBytes(), signingRoot)
    // deposit_root
    const deposit_root = computeDepositDataRoot(wrapWithBuffer(publicKey.toBytes()), withdrawalCredentials, DEPOSIT_AMOUNT, wrapWithBuffer(signature))

    return {
        pubkey: wrapWithBuffer(secretKey.toPublicKey().toBytes()).toString('hex'),
        withdrawalCredentials: withdrawalCredentials.toString('hex'),
        amount: DEPOSIT_AMOUNT,
        signature: wrapWithBuffer(signature).toString('hex'),
        depositRoot: wrapWithBuffer(deposit_root).toString('hex'),
    }
}
exports.generateDepositCredentials = generateDepositCredentials;

function computeDepositMessageRoot(pubKey, withdrawalCredentials, amount) {
    requireBuffer(pubKey);
    requireBuffer(withdrawalCredentials);
    const depositMessage = {};
    depositMessage.pubKey = pubKey;
    depositMessage.withdrawalCredentials = withdrawalCredentials;
    depositMessage.amount = BigInt(amount);
    const DepositMessage = new ssz.ContainerType({
        fields: {
            pubKey: new ssz.ByteVectorType({
                length: 48,
            }),
            withdrawalCredentials: new ssz.ByteVectorType({
                length: 32,
            }),
            amount: new ssz.BigIntUintType({
                byteLength: 8,
            }),
        },
    });
    return wrapWithBuffer(DepositMessage.hashTreeRoot(depositMessage));
}
exports.computeDepositMessageRoot = computeDepositMessageRoot;

function computeSigningRoot(objectRoot, domain) {
    requireBuffer(objectRoot);
    requireBuffer(domain);
    const domainWrappedObject = {};
    domainWrappedObject.objectRoot = objectRoot;
    domainWrappedObject.domain = domain;
    const SigningData = new ssz.ContainerType({
        fields: {
            objectRoot: new ssz.ByteVectorType({
                length: 32,
            }),
            domain: new ssz.ByteVectorType({
                length: 32,
            }),
        },
    });
    return wrapWithBuffer(SigningData.hashTreeRoot(domainWrappedObject));
}
exports.computeSigningRoot = computeSigningRoot;

function computeDepositDomain() {
    const forkVersion = wrapWithBuffer('00000000'); // MAINNET
    const domainType = wrapWithBuffer('03000000'); // DEPOSIT
    const forkDataRoot = computeDepositForkDataRoot(forkVersion);
    return Buffer.concat([domainType, forkDataRoot.slice(0, 28)])
}
exports.computeDepositDomain = computeDepositDomain;

function computeDepositForkDataRoot(forkVersion) {
    requireBuffer(forkVersion);
    const genesisValidatorsRoot = wrapWithBuffer('0000000000000000000000000000000000000000000000000000000000000000'); // For deposit, it's fixed value
    const forkData = {};
    forkData.forkVersion = forkVersion;
    forkData.genesisValidatorsRoot = genesisValidatorsRoot;
    const ForkData = new ssz.ContainerType({
        fields: {
            forkVersion: new ssz.ByteVectorType({
                length: 4,
            }),
            genesisValidatorsRoot: new ssz.ByteVectorType({
                length: 32,
            }),
        },
    });
    return wrapWithBuffer(ForkData.hashTreeRoot(forkData));
}
exports.computeDepositForkDataRoot = computeDepositForkDataRoot;

function computeDepositDataRoot(pubKey, withdrawalCredentials, amount, signature) {
    requireBuffer(pubKey);
    requireBuffer(withdrawalCredentials);
    requireBuffer(signature);
    const depositData = {};
    depositData.pubKey = pubKey;
    depositData.withdrawalCredentials = withdrawalCredentials;
    depositData.amount = BigInt(amount);
    depositData.signature = signature;
    const DepositData = new ssz.ContainerType({
        fields: {
            pubKey: new ssz.ByteVectorType({
                length: 48,
            }),
            withdrawalCredentials: new ssz.ByteVectorType({
                length: 32,
            }),
            amount: new ssz.BigIntUintType({
                byteLength: 8,
            }),
            signature: new ssz.ByteVectorType({
                length: 96,
            }),
        },
    });
    return wrapWithBuffer(DepositData.hashTreeRoot(depositData));
}
exports.computeDepositDataRoot = computeDepositDataRoot;

function calculateFunctionSignature(functionInterface) {
    return keccak('keccak256').update(functionInterface).digest('hex').substr(0, 8);
}
exports.calculateFunctionSignature = calculateFunctionSignature;