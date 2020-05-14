var Token = artifacts.require("./FulcrumToken.sol");

module.exports = function(deployer) {
  deployer.deploy(Token, 250000000, "FulcrumToken", "FULC", 5000);
};
