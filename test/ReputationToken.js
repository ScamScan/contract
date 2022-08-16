const { expect } = require("chai");

// We use `loadFixture` to share common setups (or fixtures) between tests.
// Using this simplifies your tests and makes them run faster, by taking
// advantage or Hardhat Network's snapshot functionality.
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const {BigNumber} = require("ethers");

let AIRDROP_SNAPSHOT_TIMESTAMPS;
let AIRDROP_TARGET_ADDRESSES;
let TOTAL_AIRDROP_VOLUME_PER_ROUND = 3000;

let owner;
let address1;
let address2;
let ReputationTokenFactory;
let ReputationToken;

describe("Reputation Token contract", function () {
  async function deployTokenFixture(){

    ReputationTokenFactory = await ethers.getContractFactory("ReputationToken");
    
    [owner, address1, address2] = await ethers.getSigners();

    reputationToken = await ReputationTokenFactory.deploy(
        "ScamScan",
        "SCAM",
        "1.0"
    )

    await reputationToken.deployed();

    return {reputationToken, owner, address1, address2 }
  }

  it("can give ReputationToken to other address", async function () {
    const {reputationToken, owner, address1, address2} = await deployTokenFixture();
    const SALT = "0xf2d857f4a3edcb9b78b4d503bfe733db1e3f6cdc2b7971ee739626c97e86a558";

    const domain = [
      { name: "name", type: "string" },
      { name: "version", type: "string" },
      { name: "chainId", type: "uint256" },
      { name: "verifyingContract", type: "address" },
      { name: "salt", type: "bytes32" }
    ];

    const AGREEMENT = [
      {name: "active", type: "address"}, {name: "passive", type: "address"}, {name: "uri", type: "string"}
    ]

    const domainData = {
      name: "ScamScan",
      version: "1.0",
      chainId: 31337,
      verifyingContract: reputationToken.address,
      salt: SALT
    };

    const message = {
      "active": owner.address, "passive": address1.address, "uri": "https://www.scamscan.io"
    };

    const data = JSON.stringify({
      types: {
        EIP712Domain: domain,
        Agreement: AGREEMENT
      },
      domain: domainData,
      primaryType: "Agreement",
      message: message
    });

    const provider = new ethers.providers.JsonRpcProvider();
    const sendAsyncReceipt = await provider.send('eth_signTypedData_v4', [owner.address, data]);
    console.log(sendAsyncReceipt)

    const receipt = await reputationToken.give(owner.address, address1.address, "https://www.scamscan.io", sendAsyncReceipt, 5, 5, "a")
    console.log("RECEIPT >>>>>>>>>>>>>>>>", receipt);
  });
});
