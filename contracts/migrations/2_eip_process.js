const EipProcess = artifacts.require("EipProcess");
const DATA = require('../data/eip_process.js');

module.exports = function(deployer) {
    deployer.deploy(EipProcess, ...Object.values(DATA.DEPLOY_ARGS));
};
