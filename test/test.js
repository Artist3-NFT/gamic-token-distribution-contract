const { BigNumber } = require("ethers");
const { expect } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@nomicfoundation/hardhat-network-helpers");

const TEST_ADDRESS = "0x726063423641b0d028D17E32960A0288B818783d"
const claimGasEstimate = Math.floor(220669 * 1.1)

describe("TokenDistribution", async function () {

  describe("Token fee and withdraw it.", async function () {

    it("DepositERC20AndEth and then withdraw", async () => {
      const deployedContract = await deployERC20TestToken();
      const tokenDistribution = await deployContract();
      const tokenAddress = deployedContract.address;
      const recipient = await ethers.getSigner(TEST_ADDRESS);
      const balance1 = await recipient.getBalance();
      const sendingValue = 100;
      await tokenDistribution.setFeeRate(500);
      const sendingValueAfterFee = 95;
      const [owner] = await ethers.getSigners();
      const ownerBalance = await deployedContract.balanceOf(owner.address);
      expect(Number(ownerBalance.toString())).above(sendingValue)

      await deployedContract.approve(tokenDistribution.address, sendingValue);

      let realDepositeValue = BigNumber.from(`${sendingValue}`);
      const gasPrice = await ethers.provider.getGasPrice();
      const estimatedGas = BigNumber.from(claimGasEstimate)
      const preGas = BigNumber.from(`${gasPrice * estimatedGas}`);

      await tokenDistribution.depositErc20ToRecipients(sendingValue, 1, [TEST_ADDRESS], tomorrow(), false, tokenAddress, { value: `${preGas}` });

      realDepositeValue = realDepositeValue.add(preGas);
      // console.log('1A realDepositeValue :', realDepositeValue, gasPrice, estimatedGas)

      await tokenDistribution.depositETHToRecipients(1, [TEST_ADDRESS], tomorrow(), false, 100, { value: `${realDepositeValue}` });

      await tokenDistribution.claim(0, TEST_ADDRESS, sendingValue);
      await tokenDistribution.setFeeRate(1000);
      const sendingValueAfterFee2 = 90;
      await tokenDistribution.claim(1, TEST_ADDRESS, sendingValue);

      // recipient's ERC20 balance should be increased according the feeRate.
      expect((await deployedContract.balanceOf(TEST_ADDRESS)).toString()).eq(`${sendingValueAfterFee}`)

      const balance2 = await recipient.getBalance();
      // recipient's eth balance should be increased according the feeRate.
      expect((balance2 - balance1).toString()).eq(`${sendingValueAfterFee2}`)

      await tokenDistribution.transferWithdrawShip(TEST_ADDRESS);
      const listTokensRes = await tokenDistribution.listTokens();

      // contract's array of withdrawable token list, should have 2 item.
      expect(listTokensRes.length).eq(2)
      const recipientBalance1 = await recipient.getBalance();

      // the ERC20 balance of contract should be according to the feeRate.
      expect((await deployedContract.balanceOf(tokenDistribution.address)).toString()).eq(`${(sendingValue - sendingValueAfterFee)}`)

      await tokenDistribution.withDrawAllTokens();

      const recipientBalance2 = await recipient.getBalance();

      // recipient is the withdrawer, and ETH balance should increase 10 after withdrawer.
      expect((recipientBalance2 - recipientBalance1).toString()).eq(`${(sendingValue - sendingValueAfterFee2)}`)

      // contract's ERC20 balance should be 0 after withdrawder
      expect((await deployedContract.balanceOf(tokenDistribution.address)).toString()).eq('0')

      const listTokensRes2 = await tokenDistribution.listTokens();

      // contract's array of withdrawable token list, should be empty
      expect(listTokensRes2.length).eq(0)
    });
  });

  it("DepositETHToRecipients and claim", async () => {
    const tokenDistribution = await deployContract();
    const recipient = await ethers.getSigner(TEST_ADDRESS);

    let realDepositeValue = BigNumber.from(`100`);
    const gasPrice = await ethers.provider.getGasPrice();
    const estimatedGas = BigNumber.from(claimGasEstimate)
    const preGas = BigNumber.from(`${gasPrice * estimatedGas}`);
    realDepositeValue = realDepositeValue.add(preGas);

    await tokenDistribution.depositETHToRecipients(1, [TEST_ADDRESS], tomorrow(), false, 100, { value: `${realDepositeValue}` });

    await tokenDistribution.claim(0, TEST_ADDRESS, 50);
    const balance1 = await recipient.getBalance();
    expect(balance1.toString()).eq("100")

    realDepositeValue = realDepositeValue.add(preGas);
    const preGas2 = BigNumber.from(`${Number(preGas.toString()) * 2}`)
    await tokenDistribution.depositETHToRecipients(2, [TEST_ADDRESS, TEST_ADDRESS], tomorrow(), false, 100, { value: `${realDepositeValue}` });
    await tokenDistribution.claim(1, TEST_ADDRESS, 50);
    const balance2 = await recipient.getBalance();
    expect(balance2.toString()).eq("150")

  });

  it("DepositETHToRoom and claim", async () => {
    const tokenDistribution = await deployContract();
    const recipient = await ethers.getSigner(TEST_ADDRESS);

    let realDepositeValue = BigNumber.from(`100`);
    const gasPrice = await ethers.provider.getGasPrice();
    const estimatedGas = BigNumber.from(claimGasEstimate)
    const preGas = BigNumber.from(`${gasPrice * estimatedGas}`);
    realDepositeValue = realDepositeValue.add(preGas);

    await tokenDistribution.depositETHToRoom(1, 1, tomorrow(), false, 100, { value: `${realDepositeValue}` });
    await tokenDistribution.claim(0, TEST_ADDRESS, 100);
    const balance1 = await recipient.getBalance();
    expect(balance1.toString()).eq("250")

    realDepositeValue = realDepositeValue.add(preGas);
    const preGas2 = BigNumber.from(`${Number(preGas.toString()) * 2}`)
    await tokenDistribution.depositETHToRoom(2, 1, tomorrow(), false, 100, { value: `${realDepositeValue}` });
    await tokenDistribution.claim(1, TEST_ADDRESS, 50);
    const balance2 = await recipient.getBalance();
    expect(balance2.toString()).eq("300")

    await tokenDistribution.depositETHToRoom(2, 1, now(), false, 100, { value: `${realDepositeValue}` });
    const contractBalance1 = await tokenDistribution.provider.getBalance(tokenDistribution.address)
    await tokenDistribution.claimToSender(2);
    const contractBalance2 = await tokenDistribution.provider.getBalance(tokenDistribution.address)
    expect((Number(contractBalance1.toString()) - Number(contractBalance2.toString()))).eq(100);
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

    await deployedContract.approve(tokenDistribution.address, sendingValue);

    const gasPrice = await ethers.provider.getGasPrice();
    const estimatedGas = BigNumber.from(claimGasEstimate)
    const preGas = BigNumber.from(`${gasPrice * estimatedGas}`);

    await tokenDistribution.depositErc20ToRecipients(sendingValue, 1, [TEST_ADDRESS], tomorrow(), false, tokenAddress, { value: `${preGas}` });
    await tokenDistribution.claim(0, TEST_ADDRESS, sendingValue);
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

    const gasPrice = await ethers.provider.getGasPrice();
    const estimatedGas = BigNumber.from(claimGasEstimate)
    const preGas = BigNumber.from(`${gasPrice * estimatedGas}`);

    await deployedContract.approve(tokenDistribution.address, sendingValue1);
    await tokenDistribution.depositErc20ToRoom(sendingValue1, 1, 1, tomorrow(), false, tokenAddress, { value: `${preGas}` });
    // await deployedContract.transfer(tokenDistribution.address, sendingValue1);
    await tokenDistribution.claim(0, TEST_ADDRESS, sendingValue1);
    expect((await deployedContract.balanceOf(TEST_ADDRESS)).toString()).eq(`${sendingValue1}`)
    const preGas2 = BigNumber.from(`${Number(preGas.toString()) * 2}`)

    await deployedContract.approve(tokenDistribution.address, sendingValue1);
    await tokenDistribution.depositErc20ToRoom(sendingValue1, 2, 1, tomorrow(), false, tokenAddress, { value: `${preGas2}` });
    // await deployedContract.transfer(tokenDistribution.address, sendingValue1);
    await tokenDistribution.claim(1, TEST_ADDRESS, sendingValue1 / 2);
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
  await tokenDistribution.setFeeRate(0);
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
