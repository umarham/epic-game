const main = async () => {
  const gameContractFactory = await hre.ethers.getContractFactory('MyEpicGame');
  const gameContract = await gameContractFactory.deploy(
    ["Aurion", "Atlas", "Mada"],       // Names
    ["QmdKQbqXWoGmxydWJiNrZnoA9G1tBbdDnc9ucqjGGtLpVj", // Images
    "QmNUdhVzf5ktJjWX3HnhapzJVPbHCYjJ91o6ZF6mf82Bdj", 
    "QmUBz4mSm2TokG8ibtxzgRJnuEicJFnUPdng3oKLW7heGN"],
    [100, 200, 300],                    // HP values
    [100, 100, 100],                       // Attack damage values
    [125, 125, 125], //Character crit rates 0-255
    "Nephilim", // boss name
    "Qmcy4yQC3dh5ve5niDA5xspwqUWY6Mx3AYsvWquhuQhovm", // boss image
    10000, // boss hp
    50,  // boss attack damage
    0 //Boss crit

  );
  await gameContract.deployed();
  console.log("Contract deployed to:", gameContract.address);
  let txn;
  // We only have three characters.
  // an NFT w/ the character at index 2 of our array.
  txn = await gameContract.mintCharacterNFT(0);
  await txn.wait();

  txn = await gameContract.attackBoss();
  await txn.wait();

  gameContract.on("HealthBoosted", (playerHP) => {
    console.log(`Health boosted: ${playerHP} hp`);
  });

  txn = await gameContract.purchaseHealth(20, {
    value: ethers.utils.parseEther(".02"),
  });
  await txn.wait();
  // txn = await gameContract.attackBoss();
  // await txn.wait();

  // let overrides = {
  //   // To convert Ether to Wei:
  //   value: ethers.utils.parseEther(".005"), // ether in this case MUST be a string
  // };
  // txn = await gameContract.revivePlayerNFT(overrides);
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