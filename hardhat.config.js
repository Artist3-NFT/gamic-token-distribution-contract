require("@nomiclabs/hardhat-waffle");
require("@openzeppelin/hardhat-upgrades");

const accounts = process.env.PRIVATE_KEY !== undefined ? [process.env.PRIVATE_KEY] : [];

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
module.exports = {
  defaultNetwork: "hardhat",
  networks: {
    local: {
      url: "http://127.0.0.1:8545",
      gas: 3000000,
      chainId: 31337
    },
    goerli: {
      url: "https://rpc.ankr.com/eth_goerli",
      accounts,
      gas: 3000000
    },
    sepolia: {
      url: "https://rpc.sepolia.org",
      accounts,
      gas: 3000000,
      chainId: 11155111
    },
    bscmainnet: {
      url: "https://bsc-dataseed.binance.org/",
      accounts,
      chainId: 56,
    }
  },
  etherscan: {
    apiKey: {
      sepolia: "BQ18ISXD1JMNYMZUDXWC2M1SI3UWXAFVZ9y"
    }
  },
  solidity: "0.8.4",
};