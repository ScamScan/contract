// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// You can also run a script with `npx hardhat run <script>`. If you do that, Hardhat
// will compile your contracts, add the Hardhat Runtime Environment's members to the
// global scope, and execute the script.

async function main() {

    console.log("main function called.");
    const ReputationToken = await ethers.getContractFactory("ReputationToken");
    console.log("<<<< 1");
    const reputationToken = await ReputationToken.deploy(
        "ScamScan",
        "SCAM",
        "0.1.0"
    );
    console.log("<<<< 2");

    await reputationToken.deployed();

    console.log("Reputation Token deployed to: " + reputationToken.address);
}

main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });