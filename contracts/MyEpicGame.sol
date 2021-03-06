// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
// NFT contract to inherit from.
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

// Helper functions OpenZeppelin provides.
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "./libraries/Base64.sol";
import "hardhat/console.sol";

contract MyEpicGame is ERC721 {

  // We'll hold our character's attributes in a struct. Feel free to add
  // whatever you'd like as an attribute! (ex. defense, crit chance, etc).
  struct CharacterAttributes {
    uint characterIndex;
    string name;
    string imageURI;        
    uint hp;
    uint maxHp;
    uint attackDamage;
    uint criticalRate;
  }
  struct BigBoss {
    string name;
    string imageURI;
    uint hp;
    uint maxHp;
    uint attackDamage;
    uint criticalRate;

  }
  uint256 healthPricePerUnit = 1000000 gwei;
  BigBoss public bigBoss;
  // The tokenId is the NFTs unique identifier, it's just a number that goes
  // 0, 1, 2, 3, etc.
  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  // A lil array to help us hold the default data for our characters.
  // This will be helpful when we mint new characters and need to know
  // things like their HP, AD, etc.
  CharacterAttributes[] defaultCharacters;

  // We create a mapping from the nft's tokenId => that NFTs attributes.
  mapping(uint256 => CharacterAttributes) public nftHolderAttributes;

  // A mapping from an address => the NFTs tokenId. Gives me an ez way
  // to store the owner of the NFT and reference it later.
  mapping(address => uint256) public nftHolders;

  event CharacterNFTMinted(address sender, uint256 tokenId, uint256 characterIndex);
  event AttackComplete(uint newBossHp, uint newPlayerHp);
  event PlayerRevived(uint newPlayerHP);
  event HealthBoosted(uint newPlayerHP);
  event CriticalHit(uint critHitAmount);





  // Data passed in to the contract when it's first created initializing the characters.
  // We're going to actually pass these values in from from run.js.
  constructor(
    string[] memory characterNames,
    string[] memory characterImageURIs,
    uint[] memory characterHp,
    uint[] memory characterAttackDmg,
    uint[] memory characterCriticalRate,
    string memory bossName, // These new variables would be passed in via run.js or deploy.js.
    string memory bossImageURI,
    uint bossHp,
    uint bossAttackDamage,
    uint bossCriticalRate
  )   
    ERC721("Dragon of War", "DRAGON")

  {
    // Initialize the boss. Save it to our global "bigBoss" state variable.
    bigBoss = BigBoss({
      name: bossName,
      imageURI: bossImageURI,
      hp: bossHp,
      maxHp: bossHp,
      attackDamage: bossAttackDamage,
      criticalRate: bossCriticalRate
    });

  console.log("Done initializing boss %s w/ HP %s, img %s", bigBoss.name, bigBoss.hp, bigBoss.imageURI);

    
    // Loop through all the characters, and save their values in our contract so
    // we can use them later when we mint our NFTs.
    for(uint i = 0; i < characterNames.length; i += 1) {
      defaultCharacters.push(CharacterAttributes({
        characterIndex: i,
        name: characterNames[i],
        imageURI: characterImageURIs[i],
        hp: characterHp[i],
        maxHp: characterHp[i],
        attackDamage: characterAttackDmg[i],
        criticalRate: characterCriticalRate[i]
      }));

      CharacterAttributes memory c = defaultCharacters[i];
      console.log("Done initializing %s w/ HP %s, %s Atack Damage, ", c.name, c.hp, c.attackDamage);
      console.log("img %s", c.imageURI);
    }
    // I increment tokenIds here so that my first NFT has an ID of 1.
    // More on this in the lesson!
    _tokenIds.increment();
  }

  function revivePlayerNFT() public payable{
      uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
      CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
      require (
      player.hp == 0,
      "Error: character must be ded.");
      require(msg.value == .005 ether, 'Revival costs .005 ether');
      player.hp = player.maxHp;
      console.log("nftPlayerToken %s revived", nftTokenIdOfPlayer);
      emit PlayerRevived(player.hp);
  }

  function purchaseHealth(uint256 amount) public payable{
    uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
      CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
      require (
      player.hp < player.maxHp,
      "Error: character must not be already at full health");
      uint256 hpAfterBoost = amount + player.hp;
      require(player.hp > 0, "Error: character is dead. Health isn't going to help");
      if (hpAfterBoost > player.maxHp){
        //Require correct amount was sent
        uint256 requiredFundsThisTransaction = healthPricePerUnit * amount;
        console.log("%s required for this transaction", requiredFundsThisTransaction);
        require(msg.value >= requiredFundsThisTransaction, 'Insufficient funds sent');
        
        //Calculate overage
        uint256 overage = hpAfterBoost - player.maxHp;
        console.log("Damn, you overshot there guy by about %s", overage);
        uint256 change = overage * healthPricePerUnit;
        console.log("Calculated change to give back %s", change);
        //Set hp to max
        player.hp = player.maxHp;
        //Emit event
        emit HealthBoosted(player.hp);
        //Return change
        (bool success, ) = msg.sender.call{value: change}('');
        require(success, "Returning change failed.");

      }else if (hpAfterBoost <= player.maxHp){
        //Require correct amount was sent
          uint256 requiredFundsThisTransaction = healthPricePerUnit * amount;
          console.log("%s required for this transaction", requiredFundsThisTransaction);
          require(msg.value >= requiredFundsThisTransaction, 'Insufficient funds sent');

        //set hp 
          player.hp += amount;
        //Emit event
          emit HealthBoosted(player.hp);

      }
      
  }

  function calculateCrit(uint critRate) internal view returns (bool){
    uint randomnumber = uint(keccak256(abi.encodePacked(block.timestamp, msg.sender, block.difficulty))) % 255;
    console.log("Random number for crit %s", randomnumber);
    bool returnValue = false;
    if (randomnumber <= critRate){
      console.log("Critical hit achieved");
      returnValue = true;
    }
    return returnValue;
  }

  function attackBoss() public {
  // Get the state of the player's NFT.
  uint256 nftTokenIdOfPlayer = nftHolders[msg.sender];
  CharacterAttributes storage player = nftHolderAttributes[nftTokenIdOfPlayer];
  console.log("\nPlayer w/ character %s about to attack. Has %s HP and %s AD", player.name, player.hp, player.attackDamage);
  console.log("Boss %s has %s HP and %s AD", bigBoss.name, bigBoss.hp, bigBoss.attackDamage);
  
  uint256 characterAttackDamage = player.attackDamage;
  require(player.criticalRate <= 255, "Crit rate out of bounds");
  
  if (calculateCrit(player.criticalRate) == true){
    
    characterAttackDamage = characterAttackDamage * 2;
    emit CriticalHit(characterAttackDamage);
  }


  // Make sure the player has more than 0 HP.
  require (
    player.hp > 0,
    "Error: character must have HP to attack boss."
  );

  // Make sure the boss has more than 0 HP.
  require (
    bigBoss.hp > 0,
    "Error: boss must have HP to attack boss."
  );

  // Allow player to attack boss.
  if (bigBoss.hp < player.attackDamage) {
    bigBoss.hp = 0;
  } else {
    bigBoss.hp = bigBoss.hp - player.attackDamage;
  }
   // Allow boss to attack player.
   uint256 bossAttackDamage = bigBoss.attackDamage;
   if (calculateCrit(bigBoss.criticalRate) == true){
    bossAttackDamage = bossAttackDamage * 2;
    emit CriticalHit(bossAttackDamage);
  }
  if (player.hp < bossAttackDamage) {
    player.hp = 0;
  } else {
    player.hp = player.hp - bossAttackDamage;
  }
   // Console for ease.
  console.log("Boss attacked player. New player hp: %s\n", player.hp);
  emit AttackComplete(bigBoss.hp, player.hp);

}

// Users would be able to hit this function and get their NFT based on the
  // characterId they send in!
  function mintCharacterNFT(uint _characterIndex) external {
    // Get current tokenId (starts at 1 since we incremented in the constructor).
    uint256 newItemId = _tokenIds.current();

    // The magical function! Assigns the tokenId to the caller's wallet address.
    _safeMint(msg.sender, newItemId);

    // We map the tokenId => their character attributes. More on this in
    // the lesson below.
    nftHolderAttributes[newItemId] = CharacterAttributes({
      characterIndex: _characterIndex,
      name: defaultCharacters[_characterIndex].name,
      imageURI: defaultCharacters[_characterIndex].imageURI,
      hp: defaultCharacters[_characterIndex].hp,
      maxHp: defaultCharacters[_characterIndex].hp,
      attackDamage: defaultCharacters[_characterIndex].attackDamage,
      criticalRate: defaultCharacters[_characterIndex].criticalRate
    });

    console.log("Minted NFT w/ tokenId %s and characterIndex %s", newItemId, _characterIndex);
    
    // Keep an easy way to see who owns what NFT.
    nftHolders[msg.sender] = newItemId;

    // Increment the tokenId for the next person that uses it.
    _tokenIds.increment();
    emit CharacterNFTMinted(msg.sender, newItemId, _characterIndex);

  }

  function checkIfUserHasNFT() public view returns (CharacterAttributes memory) {
      // Get the tokenId of the user's character NFT
      uint256 userNftTokenId = nftHolders[msg.sender];
      // If the user has a tokenId in the map, return thier character.
      if (userNftTokenId > 0) {
        return nftHolderAttributes[userNftTokenId];
      }
      // Else, return an empty character.
      else {
        CharacterAttributes memory emptyStruct;
        return emptyStruct;
      }
}
  function getAllDefaultCharacters() public view returns (CharacterAttributes[] memory) {
    return defaultCharacters;
  }

  function getBigBoss() public view returns (BigBoss memory) {
    return bigBoss;
  }

  function tokenURI(uint256 _tokenId) public view override returns (string memory) {
  CharacterAttributes memory charAttributes = nftHolderAttributes[_tokenId];

  string memory strHp = Strings.toString(charAttributes.hp);
  string memory strMaxHp = Strings.toString(charAttributes.maxHp);
  string memory strAttackDamage = Strings.toString(charAttributes.attackDamage);

  string memory json = Base64.encode(
    bytes(
      string(
        abi.encodePacked(
          '{"name": "',
          charAttributes.name,
          ' -- NFT #: ',
          Strings.toString(_tokenId),
          '", "description": "This is an NFT that lets people play in the game Metaverse!", "image": "ipfs://',
          charAttributes.imageURI,
          '", "attributes": [ { "trait_type": "Health Points", "value": ',strHp,', "max_value":',strMaxHp,'}, { "trait_type": "Attack Damage", "value": ',
          strAttackDamage,'} ]}'
        )
      )
    )
  );

  string memory output = string(
    abi.encodePacked("data:application/json;base64,", json)
  );
  
  return output;
}
}