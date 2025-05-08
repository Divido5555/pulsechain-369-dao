// hardhat.config.js
require("@nomiclabs/hardhat-waffle");
require("dotenv").config();

module.exports = {
  solidity: "0.7.6",
  networks: {
    pulsechain: {
      url: process.env.PULSECHAIN_RPC,
      accounts: [process.env.PRIVATE_KEY]
    }
  }
};
