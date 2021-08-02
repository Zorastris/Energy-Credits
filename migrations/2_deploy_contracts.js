const EnergyCredits = artifacts.require("EnergyCredits");
const EnergyMarket = artifacts.require("EnergyMarket");

module.exports = function(deployer) {
  await deployer.deploy(EnergyCredits);
  deployer.deploy(EnergyCredits);
  const credits = await EnergyCredits.deployed();
  await deployer.deploy(EnergyMarket, credits.address);
};
