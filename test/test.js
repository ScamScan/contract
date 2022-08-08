const { expect } = require("chai");
const { ethers } = require("hardhat");

let owner;
let secondAddr;
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

  it("should mint one SBT token to the another address", async() => {
    [owner, secondAddr] = await ethers.getSigners();
    const URI = "Reputation Token";
    const SIGNATURE = ethers.utils.formatBytes32String("SIGNATURE");
    const receipt = await ReputationToken.give(owner.address, secondAddr.address, URI, SIGNATURE);
    console.log(receipt);
    
    expect(await ReputationToken.balanceOf(secondAddr.address)).to.equal(1);
  })
});