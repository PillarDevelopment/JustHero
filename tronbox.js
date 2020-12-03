require('dotenv').config();

module.exports = {
  networks: {
    live: {
      privateKey: process.env.PRIVATE_LIVE,
      consume_user_resource_percent: 100,
      feeLimit: 1e9,
      originEnergyLimit: 1e7,
      fullHost: "https://api.trongrid.io",
      network_id: "*" // Match any network id
    },
    test: {
      privateKey: process.env.PRIVATE_SHASTA,
      consume_user_resource_percent: 100,
      feeLimit: 1e9,
      originEnergyLimit: 1e7,
      fullHost: "https://api.shasta.trongrid.io",
      network_id: "*" // Match any network id
    },
    development: {
      // For trontools/quickstart docker image
      privateKey: process.env.PRIVATE_LOCAL,
      consume_user_resource_percent: 100,
      feeLimit: 1e9,
      originEnergyLimit: 1e7,
      fullHost: "http://127.0.0.1:9090",
      network_id: "*"
    },
    production: {}
  }
};