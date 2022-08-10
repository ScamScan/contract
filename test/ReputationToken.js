const { expect } = require("chai");

// We use `loadFixture` to share common setups (or fixtures) between tests.
// Using this simplifies your tests and makes them run faster, by taking
// advantage or Hardhat Network's snapshot functionality.
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const {BigNumber} = require("ethers");

let AIRDROP_SNAPSHOT_TIMESTAMPS;
let AIRDROP_TARGET_ADDRESSES;
let TOTAL_AIRDROP_VOLUME_PER_ROUND = 3000;

describe("Reputation Token contract", function () {
  async function deployTokenFixture(){

    const ReputationToken = await ethers.getContractFactory("ReputationToken");
    
    const [owner, address1] = await ethers.getSigners();

    const reputationToken = await ReputationToken.deploy(
        "ScamScan",
        "SCAM",
        "1.0"
    )

    await reputationToken.deployed();

    return {reputationToken, owner, address1}
  }

  describe("Deployment", function () {

    it("Should assign the total supply of tokens to the owner", async function () {
      const {hardhatToken, owner} = await loadFixture(deployTokenFixture);
      const ownerBalance = await hardhatToken.balanceOf(hardhatToken.address);
      expect(await hardhatToken.totalSupply()).to.equal(ownerBalance);
    });
  });

  describe("Transactions", function () {
    it("Should transfer tokens between accounts", async function () {
      const {hardhatToken, owner, addr1, addr2, airdropToken} = await loadFixture(deployTokenFixture);

      console.log(">>>>>>>>>>>>>>>>>>>>>", await hardhatToken.getDAOName(), await hardhatToken.getIntro())

      // Transfer 50 tokens from owner to addr1
      // console.log("<<<<<<<<<<<<<<<<<<", await hardhatToken.balanceOf(owner.address));
      console.log("<<<<<<<<<<<<<<<<<<", await hardhatToken.balanceOf(hardhatToken.address));
      await expect(hardhatToken.airdropFromContractAccount(addr1.address, 50))
          .to.changeTokenBalances(hardhatToken, [hardhatToken.address, addr1], [-50, 50]);

      // Transfer 50 tokens from addr1 to addr2
      // We use .connect(signer) to send a transaction from another account
      await expect(hardhatToken.connect(addr1).transfer(addr2.address, 50))
          .to.changeTokenBalances(hardhatToken, [addr1, addr2], [-50, 50]);
    });

    it("should emit Transfer events", async function () {
      const {hardhatToken, owner, addr1, addr2} = await loadFixture(deployTokenFixture);

      // Transfer 50 tokens from owner to addr1
      // await expect(hardhatToken.transfer(addr1.address, 50))  // TODO: 이게 돼야 함?
      await expect(hardhatToken.airdropFromContractAccount(addr1.address, 50))
          .to.emit(hardhatToken, "Transfer").withArgs(owner.address, addr1.address, 50)

      // Transfer 50 tokens from addr1 to addr2
      // We use .connect(signer) to send a transaction from another account
      await expect(hardhatToken.connect(addr1).transfer(addr2.address, 50))
          .to.emit(hardhatToken, "Transfer").withArgs(addr1.address, addr2.address, 50)
    });

    it("Should fail if sender doesn't have enough tokens", async function () {
      const {hardhatToken, owner, addr1} = await loadFixture(deployTokenFixture);
      const initialOwnerBalance = await hardhatToken.balanceOf(
          owner.address
      );

      // Try to send 1 token from addr1 (0 tokens) to owner (1000 tokens).
      // `require` will evaluate false and revert the transaction.
      await expect(
          hardhatToken.connect(addr1).transfer(owner.address, 1)
      ).to.be.revertedWith("ERC20: transfer amount exceeds balance");

      // Owner balance shouldn't have changed.
      expect(await hardhatToken.balanceOf(owner.address)).to.equal(
          initialOwnerBalance
      );
    });

    it("should query airdrop state when requested", async () => {
      const {hardhatToken, owner, addr1, addr2, airdropToken} = await loadFixture(deployTokenFixture);
      expect(await airdropToken.getNumOfTotalRounds()).to.equal(AIRDROP_SNAPSHOT_TIMESTAMPS.length);
      expect(await airdropToken.getTotalAirdropVolumePerRound()).deep.equal(TOTAL_AIRDROP_VOLUME_PER_ROUND);
      expect(await airdropToken.getAirdropTargetAddresses()).deep.equal(AIRDROP_TARGET_ADDRESSES);
      expect(await airdropToken.getAirdropSnapshotTimestamps()).deep.equal(AIRDROP_SNAPSHOT_TIMESTAMPS);
    })
  });

  // describe("Transfer Tokens", async function () {
  //   it("Should store balanceUpdateHistories after transfering tokens between accounts", async () => {
  //     // given
  //     const {hardhatToken, owner, addr1, addr2} = await loadFixture(deployTokenFixture);

  //     // when: Transfer 50 tokens from owner to addr1
  //     // expect(await hardhatToken.transfer(addr1.address, ethers.utils.parseUnits('50', 18)));
  //     expect(await hardhatToken.airdropFromContractAccount(addr1.address, ethers.utils.parseUnits('50', 18)));


  //     // then
  //     // const historiesOfOwnerFirstCase = await hardhatToken.getBalanceCommitHistoryByAddress(1, owner.address);
  //     // console.log(">>>>>>>>>>>>>>>>", historiesOfOwnerFirstCase)
  //     //
  //     // expect(historiesOfOwnerFirstCase.length).to.equal(1);
  //     // expect(historiesOfOwnerFirstCase[0].balanceAfterCommit).to.equal(ethers.utils.parseUnits('999950', 18));

  //     const historiesOfAddr1FirstCase = await hardhatToken.getBalanceCommitHistoryByAddress(1, addr1.address);
  //     expect(historiesOfAddr1FirstCase.length).to.equal(1);
  //     expect(historiesOfAddr1FirstCase[0].balanceAfterCommit).to.equal(ethers.utils.parseUnits('50', 18));

  //     // when: Transfer 50 tokens from addr1 to addr2 to use connect(signer) to send a transaction from another account
  //     expect(await hardhatToken.connect(addr1).transfer(addr2.address, ethers.utils.parseUnits('30', 18)));

  //     // then
  //     const historiesOfAddr1SecondCase = await hardhatToken.getBalanceCommitHistoryByAddress(1, addr1.address);
  //     expect(historiesOfAddr1SecondCase.length).to.equal(2);
  //     expect(historiesOfAddr1SecondCase[1].balanceAfterCommit).to.equal(ethers.utils.parseUnits('20', 18));

  //     const historiesOfAddr2SecondCase = await hardhatToken.getBalanceCommitHistoryByAddress(1, addr2.address);
  //     expect(historiesOfAddr2SecondCase.length).to.equal(1);
  //     expect(historiesOfAddr2SecondCase[0].balanceAfterCommit).to.equal(ethers.utils.parseUnits('30', 18));
  //   })
  // });

  // describe("Airdrop", async function() {
  //   it("Round 1: All whitelisted addresses could get equally divided airdrop tokens", async function() {
  //     // given
  //     const {hardhatToken, owner, addr1, addr2, addr3, airdropToken} = await loadFixture(deployTokenFixture);

  //     // when
  //     await airdropToken.executeAirdropRound(hardhatToken.address);

  //     // then
  //     // expect(await hardhatToken.balanceOf(addr1.address)).to.equal(ethers.utils.parseUnits('1000', 18));
  //     // expect(await hardhatToken.balanceOf(addr2.address)).to.equal(ethers.utils.parseUnits('1000', 18));
  //     // expect(await hardhatToken.balanceOf(addr3.address)).to.equal(ethers.utils.parseUnits('1000', 18));
  //     // expect(await hardhatToken.balanceOf(addr4.address)).to.equal(ethers.utils.parseUnits('1000', 18));
  //     expect(await hardhatToken.balanceOf(addr1.address)).to.equal(1000);
  //     expect(await hardhatToken.balanceOf(addr2.address)).to.equal(1000);
  //     expect(await hardhatToken.balanceOf(addr3.address)).to.equal(1000);
  //     // expect(await hardhatToken.balanceOf(addr4.address)).to.equal(1000);
  //   });
  // })

  describe("Airdrop2", async function() {
    it("Round 2: airDropAmount Decreases after calling transfer ", async function() {
      // given
      const {hardhatToken, owner, addr1, addr2, addr3, airdropToken} = await loadFixture(deployTokenFixture);

      // when
      await airdropToken.executeAirdropRound(hardhatToken.address);

      // then

      expect(await hardhatToken.balanceOf(addr1.address)).to.equal(1000);
      expect(await hardhatToken.balanceOf(addr2.address)).to.equal(1000);
      expect(await hardhatToken.balanceOf(addr3.address)).to.equal(1000);
      
      // // when
      await hardhatToken.connect(addr1).transfer(addr3.address, 800);

      // hardhatToken.transferFrom(addr1, addr3, 500);
      await airdropToken.executeAirdropRound(hardhatToken.address);

      // // then

      expect(await hardhatToken.balanceOf(addr1.address)).to.equal(800);
      expect(await hardhatToken.balanceOf(addr2.address)).to.equal(2000);
      expect(await hardhatToken.balanceOf(addr3.address)).to.equal(2800);


    });
  })
});