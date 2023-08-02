import { writeFile } from "fs/promises";
import dotenv from "dotenv";
import esMain from "es-main";
import { deployCre8ors } from "./deploy/deployCre8ors.mjs";
import { deployStaking } from "./deploy/deployStaking.mjs";
import { deployLockup } from "./deploy/deployLockup.mjs";
import { deployMinterUtilities } from "./deploy/deployMinterUtilities.mjs";
import { deployFamilyAndFriendsMinter } from "./deploy/deployFriendsAndFamily.mjs";
import { deployPassportMinter } from "./deploy/deployPassportMinter.mjs";

dotenv.config({
  path: `.env.${process.env.CHAIN}`,
});

export async function setupContracts() {
  console.log("deploying...");
  const cre8ors = await deployCre8ors();
  const staking = await deployStaking();
  const lockup = await deployLockup();
  const passportAddress = "0x31E28672F704d6F8204e41Ec0B93EE2b1172558E";

  const minterUtilities = await deployMinterUtilities(passportAddress);
  const familyFriendsMinter = await deployFamilyAndFriendsMinter(
    cre8ors.deploy.deployedTo,
    minterUtilities.deploy.deployedTo
  );
  const passportMinter = await deployPassportMinter(
    passportAddress,
    minterUtilities.deploy.deployedTo,
    familyFriendsMinter.deploy.deployedTo
  );
  return {
    cre8ors,
    lockup,
    staking,
    minterUtilities,
    familyFriendsMinter,
    passportMinter,
  };
}

async function main() {
  const output = await setupContracts();
  const date = new Date().toISOString().slice(0, 10);
  writeFile(
    `./deployments/${date}.${process.env.CHAIN}.json`,
    JSON.stringify(output, null, 2)
  );
}

if (esMain(import.meta)) {
  // Run main
  await main();
}
