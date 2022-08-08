require("@nomicfoundation/hardhat-toolbox");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.9",
  networks: {
    ropsten: {
      url: "https://ethereum-ropsten-rpc.allthatnode.com/",
      accounts: [process.env.PRIVATE_KEY_ROPSTEN]
    }
  }
};
