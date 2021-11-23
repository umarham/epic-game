const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory("MyEpicGame");
  const gameContract = await gameContractFactory.deploy(
    ["Aurion", "Atlas", "Mada"], // Names
    [
      "QmdKQbqXWoGmxydWJiNrZnoA9G1tBbdDnc9ucqjGGtLpVj", // Images
      "QmNUdhVzf5ktJjWX3HnhapzJVPbHCYjJ91o6ZF6mf82Bdj",
      "QmUBz4mSm2TokG8ibtxzgRJnuEicJFnUPdng3oKLW7heGN",
    ],
    [100, 75, 300], // HP values
    [50, 25, 478], // Attack damage values
    [125, 200, 75], //Character crit rates 0-255
    "Nephilim", //Boss name
    "Qmcy4yQC3dh5ve5niDA5xspwqUWY6Mx3AYsvWquhuQhovm", //Boss image
    5000, //Boss HP
    50, //Boss attack damage
    0 //Boss crit
  );
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);
  // let txn;
  // // We only have three characters.
  // // an NFT w/ the character at index 2 of our array.
  // txn = await gameContract.mintCharacterNFT(2);
  // await txn.wait();

  // txn = await gameContract.attackBoss();
  // await txn.wait();

  // txn = await gameContract.attackBoss();
  // await txn.wait();
  // Get the value of the NFT's URI.
  let returnedTokenUri = await gameContract.tokenURI(1);
};

const runMain = async () => {
  try {
    await main();
    process.exit(0);
  } catch (error) {
    console.log(error);
    process.exit(1);
  }
};

runMain();