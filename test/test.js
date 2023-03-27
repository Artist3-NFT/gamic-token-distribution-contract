const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

const TEST_ADDRESS = "0x726063423641b0d028D17E32960A0288B818783d"

describe("TokenDistribution", async function () {

  it("DepositETHToRecipients and claim", async () => {
    const tokenDistribution = await deployContract();
    const recipient = await ethers.getSigner(TEST_ADDRESS);
    await tokenDistribution.depositETHToRecipients(1, [TEST_ADDRESS], tomorrow(), {value: "100"});
    await tokenDistribution.claim(0, TEST_ADDRESS);
    const balance1 = await recipient.getBalance();
    expect(balance1.toString()).eq("100")

    await tokenDistribution.depositETHToRecipients(2, [TEST_ADDRESS, TEST_ADDRESS], tomorrow(), {value: "100"});
    await tokenDistribution.claim(1, TEST_ADDRESS);
    const balance2 = await recipient.getBalance();
    expect(balance2.toString()).eq("150")

  });

  it("DepositETHToRoom and claim", async () => {
    const tokenDistribution = await deployContract();
    const recipient = await ethers.getSigner(TEST_ADDRESS);
    await tokenDistribution.depositETHToRoom(1, 1, tomorrow(), {value: "100"});
    await tokenDistribution.claim(0, TEST_ADDRESS);
    const balance1 = await recipient.getBalance();
    expect(balance1.toString()).eq("250")

    await tokenDistribution.depositETHToRoom(2, 1, tomorrow(), {value: "100"});
    await tokenDistribution.claim(1, TEST_ADDRESS);
    const balance2 = await recipient.getBalance();
    expect(balance2.toString()).eq("300")

    expect(await tokenDistribution.provider.getBalance(tokenDistribution.address)).eq("50")
    await time.setNextBlockTimestamp(tomorrow() + 3600);
    await tokenDistribution.claimToSender(1);
    expect(await tokenDistribution.provider.getBalance(tokenDistribution.address)).eq("0")
  });
});

function now() {
  return Math.floor(Date.now() / 1000)
}

function tomorrow() {
  return now() + 60 * 60 * 24
}

async function deployContract() {
  const TokenDistribution = await ethers.getContractFactory("TokenDistribution");
  const tokenDistribution = await TokenDistribution.deploy();
  await tokenDistribution.deployed();
  const accounts = await ethers.getSigners();
  await tokenDistribution.initialize(accounts[0].address);
  return tokenDistribution
}
