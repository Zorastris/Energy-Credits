import Web3 from "web3";
import tokenArtifact from "../../build/contracts/EnergyCredits.json";
import marketArtifact from "../../build/contracts/EnergyMarket.json";
import css from "./index.css";

const App = {
  web3: null,
  account: null,
  token: null,
  market: null,
  start: async function() {
    const { web3 } = this;
    
    try {
      // get contract instance
      const networkId = await web3.eth.net.getId();
      const deployedNetwork = tokenArtifact.networks[networkId];
      this.token = new web3.eth.Contract(
        tokenArtifact.abi,
        deployedNetwork.address,
      );
      this.market = new web3.eth.Contract(
        marketArtifact.abi,
        deployedNetwork.address,
      );

      // get accounts
      const accounts = await web3.eth.getAccounts();
      this.account = accounts[0];
      

      this.refreshBalance();
    } catch (error) {
      console.error("Could not connect to contract or chain.");
    }
  },

  refreshBalance: async function() {
    const { balanceOf } = this.token.methods;
    var balance = await balanceOf(this.account).call()/1000;
    console.log(this.account);
    console.log(balance);
    const balanceElement = document.getElementsByClassName("balance")[0];
    balanceElement.innerHTML = balance;
  },

  checkBalance: async function() {
    const checkAccount = document.getElementById("check-balance").value;
    const { balanceOf } = this.token.methods;
    var balance = await balanceOf(checkAccount).call()/1000;
    const checkElement = document.getElementsByClassName("check-balance-result")[0];
    checkElement.innerHTML = balance;
  },

  addAsk: async function() {
    let date = (new Date()).getTime();
    const amount = parseInt(document.getElementById("amount-ask").value);
    const price = parseInt(document.getElementById("price-ask").value);

    console.log(date);
    const { addAsk } = this.market.methods;
    await addAsk(amount, price, date).send({from: this.account});

  },

  getAsks: async function() {
    const { getAllAsks } = this.market.methods;
    var asks = await getAllAsks().call();
    console.log(asks);
    const balanceElement = document.getElementsByClassName("balance")[0];
    balanceElement.innerHTML = balance;
  },

  sendCredits: async function() {
    const amount = parseInt(document.getElementById("amount").value)*1000;
    const receiver = document.getElementById("receiver").value;

    this.setStatus("Initiating transaction... (please wait)");

    const { transfer } = this.token.methods;
    await transfer(receiver, amount).send({ from: this.account });

    this.setStatus("Transaction complete!");
    this.refreshBalance();
  },

  setStatus: function(message) {
    const status = document.getElementById("status");
    status.innerHTML = message;
  },
};

window.App = App;

window.addEventListener("load", function() {
  if (window.ethereum) {
    // use MetaMask's provider
    App.web3 = new Web3(window.ethereum);
    window.ethereum.enable(); // get permission to access accounts
  } else {
    console.warn(
      "No web3 detected. Falling back to http://127.0.0.1:8545. You should remove this fallback when you deploy live",
    );
    // fallback - use your fallback strategy (local node / hosted node + in-dapp id mgmt / fail)
    App.web3 = new Web3(
      new Web3.providers.HttpProvider("http://127.0.0.1:8545"),
    );
  }

  App.start();
});
