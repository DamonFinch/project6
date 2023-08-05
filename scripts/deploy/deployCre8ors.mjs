import { retryDeploy, retryVerify } from "../contract.mjs";
import dotenv from "dotenv";

dotenv.config({
  path: `.env.${process.env.CHAIN}`,
});

export async function deployCre8ors(root) {
  console.log("deploying Cre8ors");
  const contractName = "cre8ors";
  const contractSymbol = "CRE8";
  const _initialOwner = "0x4D977d9aEceC3776DD73F2f9080C9AF3BC31f505"; // cre8ors.eth
  const _fundsRecipient = "0xcfBf34d385EA2d5Eb947063b67eA226dcDA3DC38"; // sweetman.eth
  const _editionSize = "8888";
  const _royaltyBPS = "888";
  const publicSalePrice = "150000000000000000";
  const erc20PaymentToken = "0x0000000000000000000000000000000000000000";
  const maxSalePurchasePerAddress = 18;
  const presaleStart = "1691254500"; // Saturday, August 5, 2023 12:55:00 PM PM ET
  const presaleEnd = "18446744073709551615"; // forever
  const publicSaleStart = "1691255100"; // Saturday, August 5, 2023 1:05:00 PM  ET
  const publicSaleEnd = "18446744073709551615"; // forever
  const presaleMerkleRoot = root;

  const _salesConfig = `"(${publicSalePrice},${erc20PaymentToken},${maxSalePurchasePerAddress},${publicSaleStart},${publicSaleEnd},${presaleStart},${presaleEnd},${presaleMerkleRoot})"`;
  const _metadataRenderer = "0x209511E9fe3c526C61B7691B9308830C1d1612bE"; // from Zora
  const contractLocation = "src/Cre8ors.sol:Cre8ors";
  const args = [
    contractName,
    contractSymbol,
    _initialOwner,
    _fundsRecipient,
    _editionSize,
    _royaltyBPS,
    _salesConfig,
    _metadataRenderer,
  ];
  const dropContract = await retryDeploy(2, contractLocation, args);
  console.log(`[deployed] ${contractLocation}`);

  const _salesConfig2 = [
    publicSalePrice,
    erc20PaymentToken,
    maxSalePurchasePerAddress,
    publicSaleStart,
    publicSaleEnd,
    presaleStart,
    presaleEnd,
    presaleMerkleRoot,
  ];
  const args2 = [
    contractName,
    contractSymbol,
    _initialOwner,
    _fundsRecipient,
    _editionSize,
    _royaltyBPS,
    _salesConfig2,
    _metadataRenderer,
  ];
  await retryVerify(
    2,
    "0xe05ae2fF6D24cfE14d62C72978f4e1eCf583e956",
    contractLocation,
    args2
  );
  console.log(`[verified] ${contractLocation}`);
  const dropContractAddress = dropContract.deploy.deployedTo;
  console.log("deployed cre8ors to ", dropContractAddress);

  return dropContract;
}
