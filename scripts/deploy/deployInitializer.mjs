import { deployAndVerify } from "../contract.mjs";
import dotenv from "dotenv";

dotenv.config({
  path: `.env.${process.env.CHAIN}`,
});

export async function deployInitializer() {
  console.log("deploying Initializer");
  const contractLocation = "src/Initializer.sol:Initializer";
  const args = null;
  const contract = await deployAndVerify(contractLocation, args);
  const contractAddress = contract.deployed.deploy.deployedTo;
  console.log("deployed initializer to ", contractAddress);
  console.log("make sure to TEMPORARILY grant ADMIN role to initializer");
  console.log("make sure to setup on initializer");
  return contract.deployed;
}
