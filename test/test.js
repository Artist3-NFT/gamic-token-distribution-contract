const { BigNumber } = require("ethers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

const TEST_ADDRESS = "0x726063423641b0d028D17E32960A0288B818783d"

describe("TokenDistribution", async function () {

  it("DepositETHToRecipients and claim", async () => {
    const tokenDistribution = await deployContract();
    const recipient = await ethers.getSigner(TEST_ADDRESS);
    await tokenDistribution.depositETHToRecipients(1, [TEST_ADDRESS], tomorrow(), { value: "100" });
    await tokenDistribution.claim(0, TEST_ADDRESS);
    const balance1 = await recipient.getBalance();
    expect(balance1.toString()).eq("100")

    await tokenDistribution.depositETHToRecipients(2, [TEST_ADDRESS, TEST_ADDRESS], tomorrow(), { value: "100" });
    await tokenDistribution.claim(1, TEST_ADDRESS);
    const balance2 = await recipient.getBalance();
    expect(balance2.toString()).eq("150")

  });

  it("DepositETHToRoom and claim", async () => {
    const tokenDistribution = await deployContract();
    const recipient = await ethers.getSigner(TEST_ADDRESS);
    await tokenDistribution.depositETHToRoom(1, 1, tomorrow(), { value: "100" });
    await tokenDistribution.claim(0, TEST_ADDRESS);
    const balance1 = await recipient.getBalance();
    expect(balance1.toString()).eq("250")

    await tokenDistribution.depositETHToRoom(2, 1, tomorrow(), { value: "100" });
    await tokenDistribution.claim(1, TEST_ADDRESS);
    const balance2 = await recipient.getBalance();
    expect(balance2.toString()).eq("300")

    await tokenDistribution.depositETHToRoom(2, 1, now(), { value: "100" });
    expect((await tokenDistribution.provider.getBalance(tokenDistribution.address)).toString()).eq("150")
    await tokenDistribution.claimToSender(2);
    expect((await tokenDistribution.provider.getBalance(tokenDistribution.address)).toString()).eq("50")
  });
});

describe("TokenDistributionForErc20", async function () {

  it("DepositERC20ToRecipients and claim", async () => {
    const deployedContract = await deployERC20TestToken();
    const tokenDistribution = await deployContract();
    const tokenAddress = deployedContract.address;

    const sendingValue = 100;
    const [owner] = await ethers.getSigners();
    const ownerBalance = await deployedContract.balanceOf(owner.address);
    expect(Number(ownerBalance.toString())).above(sendingValue)

    await tokenDistribution.depositErc20ToRecipients(1, [TEST_ADDRESS], tomorrow(), tokenAddress, { value: `${sendingValue}` });
    await deployedContract.transfer(tokenDistribution.address, sendingValue);
    await tokenDistribution.claim(0, TEST_ADDRESS);
    expect((await deployedContract.balanceOf(TEST_ADDRESS)).toString()).eq(`${sendingValue}`)
  });

  it("DepositERC20ToRoom and claim", async () => {
    const deployedContract = await deployERC20TestToken();
    const tokenDistribution = await deployContract();
    const tokenAddress = deployedContract.address;

    const sendingValue1 = 200;
    const [owner] = await ethers.getSigners();
    const ownerBalance = await deployedContract.balanceOf(owner.address);
    expect(Number(ownerBalance.toString())).above(sendingValue1)

    await tokenDistribution.depositErc20ToRoom(1, 1, tomorrow(), tokenAddress, { value: `${sendingValue1}` });
    await deployedContract.transfer(tokenDistribution.address, sendingValue1);
    await tokenDistribution.claim(0, TEST_ADDRESS);
    expect((await deployedContract.balanceOf(TEST_ADDRESS)).toString()).eq(`${sendingValue1}`)


    await tokenDistribution.depositErc20ToRoom(2, 1, tomorrow(), tokenAddress, { value: `${sendingValue1}` });
    await deployedContract.transfer(tokenDistribution.address, sendingValue1);
    await tokenDistribution.claim(1, TEST_ADDRESS);
    expect((await deployedContract.balanceOf(TEST_ADDRESS)).toString()).eq("300")

    await time.setNextBlockTimestamp(tomorrow() + 3600);
    await tokenDistribution.claimToSender(1);
    expect((await deployedContract.balanceOf(tokenDistribution.address)).toString()).eq("0")
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

async function deployERC20TestToken() {
  const [owner] = await ethers.getSigners();
  const TestToken = await ethers.getContractFactory("ERC20TestToken", owner);
  const totalSupply = (10 ** 9).toString()
  const testToken = await TestToken.deploy(ethers.utils.parseEther(totalSupply));
  await testToken.deployed();
  return testToken;
}
