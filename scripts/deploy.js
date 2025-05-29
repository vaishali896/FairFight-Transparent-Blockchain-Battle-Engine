const hre = require("hardhat");

async function main() {
  const FairFight = await hre.ethers.getContractFactory("FairFight");
  const fairFight = await FairFight.deploy();

  await fairFight.deployed();
  console.log("FairFight contract deployed to:", fairFight.address);
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
