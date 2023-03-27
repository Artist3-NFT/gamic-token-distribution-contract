// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const { ethers, network, upgrade } = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

    // Obtain reference to contract and ABI.
    const TokenDistribution = await ethers.getContractFactory("TokenDistribution");
    console.log("Deploying TokenDistributionTracker to ", network.name);

    // Get the first account from the list of 20 created for you by Hardhat
    const [account1] = await ethers.getSigners();

    //  Deploy logic contract using the proxy pattern.
    const tokenDistributionTracker = await upgrades.deployProxy(
        TokenDistribution,

        //Since the logic contract has an initialize() function
        // we need to pass in the arguments to the initialize()
        // function here.
        [account1.address],

        // We don't need to expressly specify this
        // as the Hardhat runtime will default to the name 'initialize'
        { initializer: "initialize" }
    );
    await tokenDistributionTracker.deployed();

    console.log("TokenDistributionTracker deployed to:", tokenDistributionTracker.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
