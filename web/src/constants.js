const CONTRACT_ADDRESS = "0x1114bF22D7Ba9D2076F6890b69161745Afb6922D";

const transformCharacterData = (characterData) => {
  return {
    name: characterData.name,
    imageURI: characterData.imageURI,
    hp: characterData.hp.toNumber(),
    maxHp: characterData.maxHp.toNumber(),
    attackDamage: characterData.attackDamage.toNumber(),
    criticalRate: characterData.criticalRate.toNumber(),
  };
};

export { CONTRACT_ADDRESS, transformCharacterData };