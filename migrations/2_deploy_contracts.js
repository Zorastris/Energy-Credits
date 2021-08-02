const EnergyCredits = artifacts.require("EnergyCredits");
const EnergyMarket = artifacts.require("EnergyMarket");

module.exports =  function(deployer) {
  deployer.deploy(EnergyCredits)
        // Wait until the storage contract is deployed
        .then(() => EnergyCredits.deployed())
        // Deploy the InfoManager contract, while passing the address of the
        // Storage contract
        .then(() => deployer.deploy(EnergyMarket, EnergyCredits.address));
};
