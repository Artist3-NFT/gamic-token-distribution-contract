const {BigNumber} = require("ethers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

const TEST_ADDRESS = "0x726063423641b0d028D17E32960A0288B818783d"

describe("TokenDistribution", async function () {
  const TokenDistribution = await ethers.getContractFactory("TokenDistribution");
  const tokenDistribution = await TokenDistribution.deploy();
  await tokenDistribution.deployed();
  it("Deposit and claim", async function () {

    const recipient = await ethers.getSigner(TEST_ADDRESS);
    await tokenDistribution.deposit(1, tomorrow(), {value: "100"});
    await tokenDistribution.claim(0, TEST_ADDRESS);
    const balance1 = await recipient.getBalance();
    expect(balance1.toString()).eq("100")

    await tokenDistribution.deposit(2, tomorrow(), {value: "100"});
    await tokenDistribution.claim(1, TEST_ADDRESS);
    const balance2 = await recipient.getBalance();
    expect(balance2.toString()).eq("150")

  });

  it("Claim to sender", async function () {

    expect(await tokenDistribution.provider.getBalance(tokenDistribution.address)).eq("50")
    await time.setNextBlockTimestamp(tomorrow());
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
