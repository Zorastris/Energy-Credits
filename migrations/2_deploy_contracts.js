const EnergyCredits = artifacts.require("energycredits");
const EnergyMarket = artifacts.require("energymarket");

module.exports = function(deployer) {
  deployer.deploy(EnergyCredits);
  deployer.link(EnergyCredits, EnergyMarket);
  deployer.deploy(EnergyMarket);
};
