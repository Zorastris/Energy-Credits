const Migrations = artifacts.require("Migrations");
const EnergyCredits = artifacts.require("EnergyCredits");
const EnergyMarket = artifacts.require("EnergyMarket");

module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(EnergyCredits);
  deployer.deploy(EnergyMarket);
};
