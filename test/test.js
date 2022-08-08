const { expect } = require("chai");
const { ethers } = require("hardhat");

let owner;
let secondAddr;
let thirdAddr;
let ReputationTokenFactory;
let ReputationToken;

describe("Reputation Token", function () {
  it("should execute initial Deployment with totalSupply is zero", async function () {
    [owner] = await ethers.getSigners();
    ReputationTokenFactory = await ethers.getContractFactory("ReputationToken");
    ReputationToken = await ReputationTokenFactory.deploy();

    const ownerBalance = await ReputationToken.balanceOf(owner.address);
    expect(await ReputationToken.totalSupply()).to.equal(ownerBalance);
  });

  it("should mint one positive (plus) SBT token to the another address", async() => {
    [owner, secondAddr] = await ethers.getSigners();
    const URI = "Reputation Token";
    const SIGNATURE = ethers.utils.formatBytes32String("SIGNATURE");
    const ONE = 1;
    await ReputationToken.give(owner.address, secondAddr.address, ONE, URI, SIGNATURE);
    
    expect(await ReputationToken.balanceOf(secondAddr.address)).to.equal(1);
  });

  it("should mint one negative (minus) SBT token to the another address", async() => {
    [owner, secondAddr, thirdAddr] = await ethers.getSigners();
    const URI = "SAMPLE_TRANSACTION_HASH";
    const SIGNATURE = ethers.utils.formatBytes32String("SIGNATURE");
    const NEGATIVE_ONE = -1;
    await ReputationToken.give(secondAddr.address, thirdAddr.address, NEGATIVE_ONE, URI, SIGNATURE);

    expect(await ReputationToken.balanceOf(thirdAddr.address)).to.equal(-1);
  })
});