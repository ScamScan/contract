const { expect } = require("chai");

describe("Reputation Token", function () {
  it("The initial Deployment with totalSupply is zero", async function () {
    const [owner] = await ethers.getSigners();

    const ReputationTokenFactory = await ethers.getContractFactory("ReputationToken");

    const ReputationToken = await ReputationTokenFactory.deploy();

    const ownerBalance = await ReputationToken.balanceOf(owner.address);
    expect(await ReputationToken.totalSupply()).to.equal(ownerBalance);
  });
});