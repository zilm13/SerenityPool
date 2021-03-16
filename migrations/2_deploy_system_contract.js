var SystemContract = artifacts.require("SystemContract");

module.exports = function(deployer) {
    // deployment steps
    deployer.deploy(SystemContract);
};