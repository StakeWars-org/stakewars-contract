// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {ERC1155} from "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";

contract Stakewars is ERC1155, Ownable {
    uint256 public constant KAZAN = 1; // 
     uint256 public constant SUIEN = 2;
     uint256 public constant FUJIN = 3;
     uint256 public constant DOGAN = 4;
     uint256 public constant RAIZEN = 5;
     uint256 public constant SHAZAN = 6;
     uint256 public constant MIZAI = 7;
     uint256 public constant KAEZO = 8;
     uint256 public constant RENGA = 9;
     uint256 public constant RAIKA = 10;
     uint256 public constant ENKIRI = 11;
     uint256 public constant KIRISAME = 12;
     uint256 public constant SHIEN = 13;
     uint256 public constant DORO = 14;
     uint256 public constant RAIKO = 15;
     uint256 public constant ENRAI = 16;
     uint256 public constant SUIRAI = 17;
     uint256 public constant FURA = 18;
     uint256 public constant GANSHI = 19;
     uint256 public constant SHIDEN = 20;
     uint256 public constant CHAKRA = 21;

    uint256 public constant CHAKRA_DECIMALS = 18;
    
    // Village constants
    uint256 public constant HIDDEN_LEAF = 1;
    uint256 public constant HIDDEN_SAND = 2;
    uint256 public constant HIDDEN_MIST = 3;
    uint256 public constant HIDDEN_CLOUD = 4;
    
    // Track addresses that have used their free mint
    mapping(address => bool) public hasFreeMinted;
    
    // Track addresses that have used their free chakra mint
    mapping(address => bool) public hasFreeChakraMinted;
    
    // Store character costs (characterId => cost in chakra tokens with 18 decimals)
    mapping(uint256 => uint256) public characterCost;
    
    // Buff structure
    struct BuffInfo {
        uint256 effect;
        uint256 price; // in chakra tokens with 18 decimals
        uint256 remainingTurns; // number of times the buff can be used
        string name;
    }
    
    // Mapping: village => buffId => BuffInfo
    // buffId: 1-5 (corresponding to effect levels 5, 10, 15, 20, 25)
    mapping(uint256 => mapping(uint256 => BuffInfo)) public villageBuffs;
    
    // Mapping: characterId => village
    mapping(uint256 => uint256) public characterVillage;
    
    // Mapping: address => characterId => buffId => remaining uses (0 means not owned or exhausted)
    mapping(address => mapping(uint256 => mapping(uint256 => uint256))) public buffRemainingUses;
    
    constructor() ERC1155("https://game.example/api/item/{id}.json") Ownable(msg.sender) {
        _initializeVillages();
        _initializeBuffs();
    }
    
    /**
     * @dev Initialize character village assignments
     */
    function _initializeVillages() private {
        // Hidden Leaf Village (1-5)
        characterVillage[KAZAN] = HIDDEN_LEAF;
        characterVillage[SUIEN] = HIDDEN_LEAF;
        characterVillage[FUJIN] = HIDDEN_LEAF;
        characterVillage[DOGAN] = HIDDEN_LEAF;
        characterVillage[RAIZEN] = HIDDEN_LEAF;
        
        // Hidden Sand Village (6-10)
        characterVillage[SHAZAN] = HIDDEN_SAND;
        characterVillage[MIZAI] = HIDDEN_SAND;
        characterVillage[KAEZO] = HIDDEN_SAND;
        characterVillage[RENGA] = HIDDEN_SAND;
        characterVillage[RAIKA] = HIDDEN_SAND;
        
        // Hidden Mist Village (11-15)
        characterVillage[ENKIRI] = HIDDEN_MIST;
        characterVillage[KIRISAME] = HIDDEN_MIST;
        characterVillage[SHIEN] = HIDDEN_MIST;
        characterVillage[DORO] = HIDDEN_MIST;
        characterVillage[RAIKO] = HIDDEN_MIST;
        
        // Hidden Cloud Village (16-20)
        characterVillage[ENRAI] = HIDDEN_CLOUD;
        characterVillage[SUIRAI] = HIDDEN_CLOUD;
        characterVillage[FURA] = HIDDEN_CLOUD;
        characterVillage[GANSHI] = HIDDEN_CLOUD;
        characterVillage[SHIDEN] = HIDDEN_CLOUD;
    }
    
    /**
     * @dev Initialize buffs for all villages
     */
    function _initializeBuffs() private {
        // Hidden Leaf Village Buffs
        // Buff 1-2: 3 remainingTurns, Buff 3-4: 4 remainingTurns, Buff 5: 5 remainingTurns
        villageBuffs[HIDDEN_LEAF][1] = BuffInfo(5, 150 * 10 ** CHAKRA_DECIMALS, 3, "Kunai Precision");
        villageBuffs[HIDDEN_LEAF][2] = BuffInfo(10, 250 * 10 ** CHAKRA_DECIMALS, 3, "Basic Chakra Control");
        villageBuffs[HIDDEN_LEAF][3] = BuffInfo(15, 400 * 10 ** CHAKRA_DECIMALS, 4, "Leaf Whirlwind");
        villageBuffs[HIDDEN_LEAF][4] = BuffInfo(20, 600 * 10 ** CHAKRA_DECIMALS, 4, "Shadow Clone Tactics");
        villageBuffs[HIDDEN_LEAF][5] = BuffInfo(25, 850 * 10 ** CHAKRA_DECIMALS, 5, "Advanced Chakra Infusion");
        
        // Hidden Sand Village Buffs
        villageBuffs[HIDDEN_SAND][1] = BuffInfo(5, 150 * 10 ** CHAKRA_DECIMALS, 3, "Sand Shield");
        villageBuffs[HIDDEN_SAND][2] = BuffInfo(10, 250 * 10 ** CHAKRA_DECIMALS, 3, "Desert Step");
        villageBuffs[HIDDEN_SAND][3] = BuffInfo(15, 400 * 10 ** CHAKRA_DECIMALS, 4, "Sand Blade Technique");
        villageBuffs[HIDDEN_SAND][4] = BuffInfo(20, 600 * 10 ** CHAKRA_DECIMALS, 4, "Granule Barrage");
        villageBuffs[HIDDEN_SAND][5] = BuffInfo(25, 850 * 10 ** CHAKRA_DECIMALS, 5, "Hardened Sand Armor");
        
        // Hidden Mist Village Buffs
        villageBuffs[HIDDEN_MIST][1] = BuffInfo(5, 150 * 10 ** CHAKRA_DECIMALS, 3, "Water Shuriken");
        villageBuffs[HIDDEN_MIST][2] = BuffInfo(10, 250 * 10 ** CHAKRA_DECIMALS, 3, "Mist Veil");
        villageBuffs[HIDDEN_MIST][3] = BuffInfo(15, 400 * 10 ** CHAKRA_DECIMALS, 4, "Aqua Blade Formation");
        villageBuffs[HIDDEN_MIST][4] = BuffInfo(20, 600 * 10 ** CHAKRA_DECIMALS, 4, "Water Wall Defense");
        villageBuffs[HIDDEN_MIST][5] = BuffInfo(25, 850 * 10 ** CHAKRA_DECIMALS, 5, "Hydro Step Mastery");
        
        // Hidden Cloud Village Buffs
        villageBuffs[HIDDEN_CLOUD][1] = BuffInfo(5, 150 * 10 ** CHAKRA_DECIMALS, 3, "Static Kunai");
        villageBuffs[HIDDEN_CLOUD][2] = BuffInfo(10, 250 * 10 ** CHAKRA_DECIMALS, 3, "Lightning Step");
        villageBuffs[HIDDEN_CLOUD][3] = BuffInfo(15, 400 * 10 ** CHAKRA_DECIMALS, 4, "Electric Palm Strike");
        villageBuffs[HIDDEN_CLOUD][4] = BuffInfo(20, 600 * 10 ** CHAKRA_DECIMALS, 4, "Thunder Charge");
        villageBuffs[HIDDEN_CLOUD][5] = BuffInfo(25, 850 * 10 ** CHAKRA_DECIMALS, 5, "Storm Edge Technique");
    }
    
    /**
     * @dev Mints a character NFT to the specified address (free mint, one per address)
     * @param to The address to mint the character to
     * @param characterId The ID of the character to mint (1-20)
     */
    function mintCharacter(address to, uint256 characterId) external {
        require(characterId >= KAZAN && characterId <= SHIDEN, "Invalid character ID");
        require(!hasFreeMinted[to], "Address has already used free mint");
        hasFreeMinted[to] = true;
        _mint(to, characterId, 1, "");
    }

    /**
     * @dev Mints chakra tokens to the specified address (free mint, one per address)
     * @param to The address to mint chakra to
     * Example: To mint 100 chakra, pass 100 * 10^18
     */
    function mintChakra(address to) external {
        require(to != address(0), "Cannot mint to zero address");
        require(!hasFreeChakraMinted[to], "Address has already used free chakra mint");
        hasFreeChakraMinted[to] = true;
        _mint(to, CHAKRA, 400 * 10 ** CHAKRA_DECIMALS, "");
    }

    /**
     * @dev Mints a character NFT by paying with chakra tokens
     * @param characterId The ID of the character to mint (1-20)
     * @param cost The cost in chakra tokens (in smallest unit, 18 decimals)
     * @notice User must approve this contract to spend their chakra tokens first
     * @notice 60% of the cost is burned, 40% is sent to the contract owner
     */
    function mintCharacterWithChakra(uint256 characterId, uint256 cost) external {
        require(characterId >= KAZAN && characterId <= SHIDEN, "Invalid character ID");
        require(cost > 0, "Cost must be greater than 0");
        require(isApprovedForAll(msg.sender, address(this)), "Contract not approved to spend chakra");
        
        address user = msg.sender;
        address ownerAddress = owner();
        require(ownerAddress != address(0), "Owner address is zero");
        
        uint256 burnAmount = (cost * 60) / 100; // 60% to burn
        uint256 ownerAmount = cost - burnAmount; // 40% to owner
        
        // Burn 60% of the chakra directly from user
        if (burnAmount > 0) {
            uint256[] memory burnIds = new uint256[](1);
            uint256[] memory burnValues = new uint256[](1);
            burnIds[0] = CHAKRA;
            burnValues[0] = burnAmount;
            _update(user, address(0), burnIds, burnValues);
        }
        
        // Transfer 40% to owner
        if (ownerAmount > 0) {
            uint256[] memory transferIds = new uint256[](1);
            uint256[] memory transferValues = new uint256[](1);
            transferIds[0] = CHAKRA;
            transferValues[0] = ownerAmount;
            _update(user, ownerAddress, transferIds, transferValues);
        }
        
        // Mint the character to the user
        _mint(user, characterId, 1, "");
    }

    /**
     * @dev Updates the cost for a specific character (only callable by owner)
     * @param characterId The ID of the character to update cost for (1-20)
     * @param cost The new cost in chakra tokens (in smallest unit, 18 decimals)
     */
    function setCharacterCost(uint256 characterId, uint256 cost) external onlyOwner {
        require(characterId >= KAZAN && characterId <= SHIDEN, "Invalid character ID");
        characterCost[characterId] = cost;
    }

    /**
     * @dev Purchase a buff for a character using chakra tokens
     * @param characterId The ID of the character (1-20)
     * @param buffId The ID of the buff to purchase (1-5)
     * @notice User must own the character and approve this contract to spend chakra
     * @notice Character can only purchase buffs from their own village
     */
    function purchaseBuff(uint256 characterId, uint256 buffId) external {
        require(characterId >= KAZAN && characterId <= SHIDEN, "Invalid character ID");
        require(buffId >= 1 && buffId <= 5, "Invalid buff ID");
        require(balanceOf(msg.sender, characterId) > 0, "You don't own this character");
        require(buffRemainingUses[msg.sender][characterId][buffId] == 0, "Buff already purchased or not exhausted");
        
        uint256 village = characterVillage[characterId];
        require(village != 0, "Character village not set");
        
        BuffInfo memory buff = villageBuffs[village][buffId];
        require(buff.price > 0, "Buff does not exist");
        
        require(isApprovedForAll(msg.sender, address(this)), "Contract not approved to spend chakra");
        require(balanceOf(msg.sender, CHAKRA) >= buff.price, "Insufficient chakra");
        
        address ownerAddress = owner();
        require(ownerAddress != address(0), "Owner address is zero");
        
        uint256 burnAmount = (buff.price * 60) / 100; // 60% to burn
        uint256 ownerAmount = buff.price - burnAmount; // 40% to owner
        
        // Burn 60% of the chakra directly from user
        if (burnAmount > 0) {
            uint256[] memory burnIds = new uint256[](1);
            uint256[] memory burnValues = new uint256[](1);
            burnIds[0] = CHAKRA;
            burnValues[0] = burnAmount;
            _update(msg.sender, address(0), burnIds, burnValues);
        }
        
        // Transfer 40% to owner
        if (ownerAmount > 0) {
            uint256[] memory transferIds = new uint256[](1);
            uint256[] memory transferValues = new uint256[](1);
            transferIds[0] = CHAKRA;
            transferValues[0] = ownerAmount;
            _update(msg.sender, ownerAddress, transferIds, transferValues);
        }
        
        // Set remaining uses to the buff's remainingTurns
        buffRemainingUses[msg.sender][characterId][buffId] = buff.remainingTurns;
    }

    /**
     * @dev Increase remaining uses for a buff (refill uses)
     * @param characterId The ID of the character (1-20)
     * @param buffId The ID of the buff (1-5)
     * @param amount The amount to increase remaining uses by
     */
    function increaseBuffUse(uint256 characterId, uint256 buffId, uint256 amount) external {
        require(characterId >= KAZAN && characterId <= SHIDEN, "Invalid character ID");
        require(buffId >= 1 && buffId <= 5, "Invalid buff ID");
        require(balanceOf(msg.sender, characterId) > 0, "You don't own this character");
        require(buffRemainingUses[msg.sender][characterId][buffId] > 0, "You don't own this buff for this character");
        require(amount > 0, "Amount must be greater than 0");
        
        buffRemainingUses[msg.sender][characterId][buffId] += amount;
    }

    /**
     * @dev Decrease remaining uses for a buff (use the buff)
     * @param characterId The ID of the character (1-20)
     * @param buffId The ID of the buff (1-5)
     * @param amount The amount to decrease remaining uses by (usually 1)
     */
    function decreaseBuffUse(uint256 characterId, uint256 buffId, uint256 amount) external {
        require(characterId >= KAZAN && characterId <= SHIDEN, "Invalid character ID");
        require(buffId >= 1 && buffId <= 5, "Invalid buff ID");
        require(balanceOf(msg.sender, characterId) > 0, "You don't own this character");
        require(buffRemainingUses[msg.sender][characterId][buffId] >= amount, "Not enough remaining uses");
        require(amount > 0, "Amount must be greater than 0");
        
        buffRemainingUses[msg.sender][characterId][buffId] -= amount;
    }

    /**
     * @dev Get buff information for a village
     * @param village The village ID (1-4)
     * @param buffId The buff ID (1-5)
     * @return effect The effect value of the buff
     * @return price The price of the buff in chakra tokens
     * @return remainingTurns The number of times the buff can be used
     * @return name The name of the buff
     */
    function getBuffInfo(uint256 village, uint256 buffId) external view returns (uint256 effect, uint256 price, uint256 remainingTurns, string memory name) {
        BuffInfo memory buff = villageBuffs[village][buffId];
        return (buff.effect, buff.price, buff.remainingTurns, buff.name);
    }

    /**
     * @dev Get character's buff remaining uses for a specific address
     * @param user The address to check
     * @param characterId The ID of the character (1-20)
     * @param buffId The ID of the buff (1-5)
     * @return remainingUses The number of remaining uses (0 means not owned or exhausted)
     */
    function getBuffStatus(address user, uint256 characterId, uint256 buffId) external view returns (uint256 remainingUses) {
        return buffRemainingUses[user][characterId][buffId];
    }

    /**
     * @dev Get all character IDs owned by a user
     * @param user The address to check
     * @return characterIds Array of character IDs owned by the user
     */
    function getCharactersOwnedByUser(address user) external view returns (uint256[] memory characterIds) {
        uint256 count = 0;
        
        // First pass: count how many characters the user owns
        for (uint256 i = KAZAN; i <= SHIDEN; i++) {
            if (balanceOf(user, i) > 0) {
                count++;
            }
        }
        
        // Second pass: populate the array
        characterIds = new uint256[](count);
        uint256 index = 0;
        for (uint256 i = KAZAN; i <= SHIDEN; i++) {
            if (balanceOf(user, i) > 0) {
                characterIds[index] = i;
                index++;
            }
        }
        
        return characterIds;
    }
}
