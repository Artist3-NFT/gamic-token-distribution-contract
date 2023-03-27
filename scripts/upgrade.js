const { ethers, upgrades } = require("hardhat");

async function main() {
    const deployedProxyAddress = process.env.PROXY_CONTRACT_ADDRESS;

    const TokenDistribution = await ethers.getContractFactory(
        "TokenDistribution"
    );
    console.log("Upgrading TokenDistribution...");

    await upgrades.upgradeProxy(deployedProxyAddress, TokenDistribution);
    console.log("TokenDistribution upgraded");
}

main();
