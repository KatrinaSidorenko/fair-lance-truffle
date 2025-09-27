const JobFactory = artifacts.require("JobFactory");

module.exports = function (deployer) {
  deployer.deploy(JobFactory);
};