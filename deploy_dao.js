const { ethers } = require("hardhat");

async function main() {
  const [deployer] = await ethers.getSigners();
  console.log("Deploying contracts with:", deployer.address);

  // Deploy DAOToken
  const Token = await ethers.getContractFactory("DAOToken");
  const token = await Token.deploy("PulseDAO", "PDAO", ethers.utils.parseEther("100000"));
  await token.deployed();
  console.log("DAOToken deployed to:", token.address);

  // Deploy Treasury
  const Treasury = await ethers.getContractFactory("Treasury");
  const treasury = await Treasury.deploy();
  await treasury.deployed();
  console.log("Treasury deployed to:", treasury.address);

  // Deploy DAOConfig in COMPANY mode (1)
  const DAOConfig = await ethers.getContractFactory("DAOConfig");
  const daoConfig = await DAOConfig.deploy(1);
  await daoConfig.deployed();
  console.log("DAOConfig deployed to:", daoConfig.address);

  await daoConfig.initialize(token.address, treasury.address);
  console.log("DAOConfig initialized");

  // Deploy Governance
  const Governance = await ethers.getContractFactory("Governance");
  const governance = await Governance.deploy(token.address);
  await governance.deployed();
  console.log("Governance deployed to:", governance.address);

  // Set Governance and Multisig Wallet
  await treasury.setGovernanceContract(governance.address);
  await treasury.setMultiSigWallet(deployer.address); // Replace with PulseSafe multisig
  await treasury.setAccessMode(2); // Hybrid mode
  console.log("Treasury configured");

  // Transfer 100% token supply to treasury
  const totalSupply = await token.totalSupply();
  await token.transfer(treasury.address, totalSupply);
  console.log("All tokens sent to Treasury");

  // Enable voting
  await daoConfig.enableVoting();
  console.log("Voting enabled");
}

main().catch((error) => {
  console.error(error);
  process.exitCode = 1;
});
