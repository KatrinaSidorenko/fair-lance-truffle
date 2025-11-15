const EscrowManager = artifacts.require("EscrowManager");

module.exports = function (deployer) {
  deployer.deploy(EscrowManager);
};
