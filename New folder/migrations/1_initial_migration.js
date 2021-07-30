const Migrations = artifacts.require("Migrations");
const EnergyCredits = artifacts.require("energycredits");
const EnergyMarket = artifacts.require("energymarket");


module.exports = function (deployer) {
  deployer.deploy(Migrations);
  deployer.deploy(EnergyCredits);
  deployer.deploy(EnergyMarket);
};
