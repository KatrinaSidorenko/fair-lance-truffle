module.exports = {
  networks: {
    development: {
      host: "127.0.0.1",
      port: 8545,
      network_id: "*", // Match any network id,
      gasPrice: 0
    }
  },
  compilers: {
    solc: {
      version: "0.8.13" // Specify Solidity version
    }
  }
};