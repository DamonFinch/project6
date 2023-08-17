import { deployAndVerify } from "../contract.mjs";
import dotenv from "dotenv";

dotenv.config({
  path: `.env.${process.env.CHAIN}`,
});

export async function deployTransfers(cre8orsNftAddress) {
  console.log("deploying Transferv0.1 Hook");
  const contractLocation = "src/hooks/Transfersv0_1.sol:TransferHookv0_1";
  const ERC6551Registry = "0x0000000000000000000000000000000000000000"; // https://docs.tokenbound.org/contracts/deployments#registry
  const ERC6551Implementation = "0x0000000000000000000000000000000000000000"; // https://docs.tokenbound.org/contracts/deployments#account-implementation
  const args = [cre8orsNftAddress, ERC6551Registry, ERC6551Implementation];
  const contract = await deployAndVerify(contractLocation, args);
  const contractAddress = contract.deployed.deploy.deployedTo;
  console.log("deployed transfer hook to ", contractAddress);
  console.log(
    "make sure to call cre8ors.setHook(0) for beforeTokenTransferHook"
  );
  console.log(
    "make sure to call cre8ors.setHook(1) for afterTokenTransferHook"
  );
  return contract.deployed;
}

const GOERLI_CRE8ORS = "0x68C885f0954094C59847E6FeB252Fe5B4b0451Ba";
await deployTransfers(GOERLI_CRE8ORS);
